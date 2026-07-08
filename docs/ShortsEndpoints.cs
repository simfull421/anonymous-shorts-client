using MySqlConnector;

namespace AnonymousShortsApi;

// extension method(확장 메서드)를 활용해 Program.cs의 짐을 덜어줍니다.
public static class ShortsEndpoints
{
    // [UC09] 심사관 Audit 토큰을 메모리에서 관리 (MVP: 서버 재시작 시 초기화)
    private static readonly HashSet<string> _activeAuditTokens = new();

    public static void MapShortsEndpoints(this WebApplication app)
    {
        // 묶음 처리를 위해 그룹화(Prefix)를 해줍니다.
        var group = app.MapGroup("/api/shorts");

        // [API 1] 쇼츠 업로드 (POST /api/shorts) - 크레딧 결제 트랜잭션 적용
        group.MapPost("/", async (ShortRequest req, MySqlConnection connection) =>
        {
            await connection.OpenAsync();
            // 트랜잭션 시작 (이제부터 일어나는 DB 작업은 한 묶음으로 처리됨)
            using var transaction = await connection.BeginTransactionAsync(); 

            try
            {
                // 1. 유저의 지갑을 열어 크레딧 잔액 확인 (FOR UPDATE로 다른 요청이 동시에 돈을 빼가는 것을 막음)
                string checkCreditSql = "SELECT credit_balance FROM UserWallet WHERE uuid = @uuid FOR UPDATE";
                using var checkCmd = new MySqlCommand(checkCreditSql, connection, transaction);
                checkCmd.Parameters.AddWithValue("@uuid", req.CreatorUuid);
                
                var creditObj = await checkCmd.ExecuteScalarAsync();
                
                // 지갑 자체가 없거나, 크레딧이 10 미만이면 403(권한 없음) 에러를 뱉고 튕겨냄
                if (creditObj == null || Convert.ToInt32(creditObj) < 10) 
                {
                    return Results.Json(new { Message = "글을 작성하기 위한 크레딧(10)이 부족하거나 지갑이 없습니다. 다른 글에 투표하여 크레딧을 모아보세요!" }, statusCode: 403);
                }

                // 2. 지갑에서 10 크레딧 차감
                string deductSql = "UPDATE UserWallet SET credit_balance = credit_balance - 10 WHERE uuid = @uuid";
                using var deductCmd = new MySqlCommand(deductSql, connection, transaction);
                deductCmd.Parameters.AddWithValue("@uuid", req.CreatorUuid);
                await deductCmd.ExecuteNonQueryAsync();

                // 3. 쇼츠 글 등록
                string insertSql = @"
                    INSERT INTO Shorts (creator_uuid, language_code, text_content, custom_buttons, bgm_id) 
                    VALUES (@uuid, @lang, @text, @buttons, @bgm)";
                using var insertCmd = new MySqlCommand(insertSql, connection, transaction);
                insertCmd.Parameters.AddWithValue("@uuid", req.CreatorUuid);
                insertCmd.Parameters.AddWithValue("@lang", req.LanguageCode);
                insertCmd.Parameters.AddWithValue("@text", req.TextContent);
                insertCmd.Parameters.AddWithValue("@buttons", req.CustomButtons);
                insertCmd.Parameters.AddWithValue("@bgm", req.BgmId);
                await insertCmd.ExecuteNonQueryAsync();

                // 4. 돈 빼고 글 쓰는게 모두 성공했으므로 최종 승인(Commit)
                await transaction.CommitAsync(); 
                return Results.Created("/api/shorts", new { Message = "10 크레딧이 차감되었고, 쇼츠가 성공적으로 업로드되었습니다." });
            }
            catch (Exception ex)
            {
                // 에러가 나면 차감했던 돈을 다시 돌려놓음(Rollback)
                await transaction.RollbackAsync(); 
                return Results.Problem(ex.Message);
            }
        });

        // [API 2] 쇼츠 피드 조회 (GET /api/shorts) - REQ-13 시간 감가상각 알고리즘 반영
        group.MapGet("/", async (string lang, MySqlConnection connection) =>
        {
            try
            {
                await connection.OpenAsync();
                
                // TIMESTAMPDIFF를 이용해 분(Minute) 단위 경과 시간을 구한 뒤 시간(Hour)으로 환산합니다.
                // POW(값, 1.5)를 사용하여 분모에 중력(Gravity=1.5) 지수를 적용합니다.
                // 투표수가 0일 때 분자가 0이 되어 신규 글끼리 순위가 꼬이는 것을 막기 위해 (total_votes + 1) 정규화를 적용합니다.
                string sql = @"
                    SELECT id, text_content, custom_buttons, total_votes, bgm_id, created_at,
                           ((total_votes + 1) / POW((TIMESTAMPDIFF(MINUTE, created_at, NOW()) / 60.0) + 2, 1.5)) AS ranking_score
                    FROM Shorts 
                    WHERE status = 'Active' 
                      AND language_code = @lang 
                      AND created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
                    ORDER BY ranking_score DESC 
                    LIMIT 10";

                using var command = new MySqlCommand(sql, connection);
                command.Parameters.AddWithValue("@lang", lang);
                
                using var reader = await command.ExecuteReaderAsync();
                var shortsList = new List<object>();

                while (await reader.ReadAsync())
                {
                    shortsList.Add(new
                    {
                        Id = reader.GetInt64("id"),
                        Text = reader.GetString("text_content"),
                        Buttons = reader.GetString("custom_buttons"),
                        Votes = reader.GetInt32("total_votes"),
                        BgmId = reader.IsDBNull(reader.GetOrdinal("bgm_id")) ? null : reader.GetString("bgm_id"),
                        Score = reader.GetDouble("ranking_score"), // 디버깅용 랭킹 스코어 포함
                        CreatedAt = reader.GetDateTime("created_at")
                    });
                }
                return Results.Ok(shortsList);
            }
            catch (Exception ex)
            {
                return Results.Problem(ex.Message);
            }
        });
        // [API 3] 마이페이지: 내 쇼츠 히스토리 조회 (GET /api/shorts/my)
        group.MapGet("/my", async (string uuid, MySqlConnection connection) =>
        {
            try
            {
                await connection.OpenAsync();
                
                // 메인 피드와 달리, 내 글은 24시간이 지나서 'Expired' 되었거나 
                // 신고를 받아 'Blind' 처리된 글도 모두 볼 수 있어야 합니다.
                string sql = @"
                    SELECT id, text_content, custom_buttons, total_votes, status, created_at 
                    FROM Shorts 
                    WHERE creator_uuid = @uuid 
                    ORDER BY created_at DESC 
                    LIMIT 50"; // 최근 50개까지만 보여줌

                using var command = new MySqlCommand(sql, connection);
                command.Parameters.AddWithValue("@uuid", uuid);
                
                using var reader = await command.ExecuteReaderAsync();
                var myShortsList = new List<object>();

                while (await reader.ReadAsync())
                {
                    myShortsList.Add(new
                    {
                        Id = reader.GetInt64("id"),
                        Text = reader.GetString("text_content"),
                        Buttons = reader.GetString("custom_buttons"),
                        Votes = reader.GetInt32("total_votes"),
                        Status = reader.GetString("status"), // 생존 여부 (Active, Blind, Expired)
                        CreatedAt = reader.GetDateTime("created_at")
                    });
                }
                return Results.Ok(myShortsList);
            }
            catch (Exception ex)
            {
                return Results.Problem(ex.Message);
            }
        });
        // --------------------------------------------------------
        // [API 4] 감정 투표 및 크레딧 획득 (POST /api/shorts/vote)
        // --------------------------------------------------------
        group.MapPost("/vote", async (VoteRequest req, MySqlConnection connection) =>
        {
            await connection.OpenAsync();
            using var transaction = await connection.BeginTransactionAsync();

            try
            {
                // 1. 해당 쇼츠의 JSON 버튼 데이터와 현재 총 투표수를 가져옴 (락 적용)
                string getShortsSql = "SELECT custom_buttons, total_votes FROM Shorts WHERE id = @id FOR UPDATE";
                using var getCmd = new MySqlCommand(getShortsSql, connection, transaction);
                getCmd.Parameters.AddWithValue("@id", req.ShortsId);
                
                using var reader = await getCmd.ExecuteReaderAsync();
                if (!await reader.ReadAsync())
                {
                    return Results.NotFound(new { Message = "존재하지 않거나 삭제된 쇼츠입니다." });
                }

                string jsonButtons = reader.GetString("custom_buttons");
                int currentTotalVotes = reader.GetInt32("total_votes");
                await reader.CloseAsync(); // 리더는 빠르게 닫아줍니다.

                // 2. C#단에서 JSON 파싱 후 유저가 누른 버튼 인덱스의 votes 값을 +1 시킵니다.
                // (역정규화 설계: JSON 내부 숫자 변경 및 외부 total_votes 컬럼 동시 +1)
                // 2. C#단에서 명확한 클래스 구조(ButtonDto)로 파싱하여 타입 에러를 원천 차단합니다.
                var buttons = System.Text.Json.JsonSerializer.Deserialize<List<ButtonDto>>(jsonButtons);
                if (buttons == null)
                {
                    return Results.BadRequest(new { Message = "버튼 데이터 파싱에 실패했습니다." });
                }

                bool buttonFound = false;
                foreach (var btn in buttons)
                {
                    if (btn.index == req.ButtonIndex)
                    {
                        btn.votes += 1; // 강한 타입이므로 캐스팅 없이 바로 연산 가능
                        buttonFound = true;
                        break;
                    }
                }

                if (!buttonFound)
                {
                    return Results.BadRequest(new { Message = "올바르지 않은 버튼 인덱스입니다." });
                }

                string updatedJson = System.Text.Json.JsonSerializer.Serialize(buttons);

                // 3. Shorts 테이블 업데이트 (시간 감가상각 랭킹에 즉시 반영됨)
                string updateShortsSql = "UPDATE Shorts SET custom_buttons = @buttons, total_votes = total_votes + 1 WHERE id = @id";
                using var updateCmd = new MySqlCommand(updateShortsSql, connection, transaction);
                updateCmd.Parameters.AddWithValue("@buttons", updatedJson);
                updateCmd.Parameters.AddWithValue("@id", req.ShortsId);
                await updateCmd.ExecuteNonQueryAsync();

                // 4. 보상 시스템: 투표한 유저(UUID) 지갑에 1 크레딧 지급 (지갑이 없으면 최초 생성)
                string rewardSql = @"
                    INSERT INTO UserWallet (uuid, credit_balance, role) 
                    VALUES (@uuid, 1, 'User') 
                    ON DUPLICATE KEY UPDATE credit_balance = credit_balance + 1";
                    
                using var rewardCmd = new MySqlCommand(rewardSql, connection, transaction);
                rewardCmd.Parameters.AddWithValue("@uuid", req.VoterUuid);
                await rewardCmd.ExecuteNonQueryAsync();

                await transaction.CommitAsync();
                return Results.Ok(new { Message = "투표가 반영되었고, 1 크레딧을 획득했습니다.", TotalVotes = currentTotalVotes + 1 });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return Results.Problem(ex.Message);
            }
        });

        // --------------------------------------------------------
        // [API 5] 어뮤징 콘텐츠 신고 및 매장 (POST /api/shorts/report)
        // --------------------------------------------------------
        group.MapPost("/report", async (ReportRequest req, MySqlConnection connection) =>
        {
            await connection.OpenAsync();
            using var transaction = await connection.BeginTransactionAsync();

            try
            {
                // 1. 신고 로그 기록 (ReportLog)
                string insertReportSql = "INSERT INTO ReportLog (target_shorts_id, reporter_uuid) VALUES (@shortsId, @reporterUuid)";
                using var insertCmd = new MySqlCommand(insertReportSql, connection, transaction);
                insertCmd.Parameters.AddWithValue("@shortsId", req.ShortsId);
                insertCmd.Parameters.AddWithValue("@reporterUuid", req.ReporterUuid);
                await insertCmd.ExecuteNonQueryAsync();

                // 2. 실시간 신고 누적 횟수 조회 (슬라이딩 윈도우: 최근 1시간 내 신고만 카운트 - SAD §6.2)
                string countReportSql = @"
                    SELECT COUNT(*) FROM ReportLog 
                    WHERE target_shorts_id = @shortsId 
                      AND created_at >= DATE_SUB(NOW(), INTERVAL 1 HOUR)";
                using var countCmd = new MySqlCommand(countReportSql, connection, transaction);
                countCmd.Parameters.AddWithValue("@shortsId", req.ShortsId);
                long reportCount = Convert.ToInt64(await countCmd.ExecuteScalarAsync());

                // 3. SystemConfig 테이블에서 임계치(BLIND_REPORT_THRESHOLD) 동적 로드
                string thresholdSql = "SELECT config_value FROM SystemConfig WHERE config_key = 'BLIND_REPORT_THRESHOLD'";
                using var thresholdCmd = new MySqlCommand(thresholdSql, connection, transaction);
                int threshold = Convert.ToInt32(await thresholdCmd.ExecuteScalarAsync());

                string statusMessage = "신고가 정상적으로 접수되었습니다.";

                // 4. 임계치 돌파 시 즉시 매장(Blind) 처리 (REQ-03, REQ-08 충족)
                if (reportCount >= threshold)
                {
                    string blindSql = "UPDATE Shorts SET status = 'Blind' WHERE id = @shortsId";
                    using var blindCmd = new MySqlCommand(blindSql, connection, transaction);
                    blindCmd.Parameters.AddWithValue("@shortsId", req.ShortsId);
                    await blindCmd.ExecuteNonQueryAsync();
                    statusMessage = "해당 콘텐츠가 누적 신고 임계치를 초과하여 즉시 피드에서 블라인드(매장) 처리되었습니다.";
                }

                await transaction.CommitAsync();
                return Results.Ok(new { Message = statusMessage, CurrentReports = reportCount });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return Results.Problem(ex.Message);
            }
        });

        // ========================================================
        // [API 6] 심사관 로그인 (POST /api/shorts/admin/login)
        // UC09 기본흐름: 비밀 코드 검증 → Audit 토큰 발급
        // ========================================================
        group.MapPost("/admin/login", async (AdminLoginRequest req, MySqlConnection connection) =>
        {
            try
            {
                await connection.OpenAsync();

                // SystemConfig 테이블에서 REVIEWER_SECRET_CODE의 config_string 조회
                string sql = "SELECT config_string FROM SystemConfig WHERE config_key = 'REVIEWER_SECRET_CODE'";
                using var cmd = new MySqlCommand(sql, connection);
                var secretObj = await cmd.ExecuteScalarAsync();

                if (secretObj == null || secretObj.ToString() != req.SecretCode)
                {
                    // UC09 예외흐름 E2: 인증 실패 → 모달 즉시 닫기
                    return Results.Json(
                        new { Message = "인증에 실패했습니다." },
                        statusCode: 401);
                }

                // 인증 성공 → Audit 토큰 발급 (GUID 기반)
                string auditToken = Guid.NewGuid().ToString("N");
                _activeAuditTokens.Add(auditToken);

                return Results.Ok(new
                {
                    Message = "심사관 모드가 활성화되었습니다.",
                    AuditToken = auditToken,
                    Credit = 999 // UC09 기본흐름 5: 무제한 크레딧 표시
                });
            }
            catch (Exception ex)
            {
                return Results.Problem(ex.Message);
            }
        });

        // ========================================================
        // [API 7] 심사관 전용 샌드박스 피드 (GET /api/shorts/sandbox)
        // UC09 기본흐름 5: 일반 피드와 분리된 테스트 피드
        // ========================================================
        group.MapGet("/sandbox", async (string token, MySqlConnection connection) =>
        {
            // 토큰 유효성 검증
            if (!_activeAuditTokens.Contains(token))
            {
                return Results.Json(
                    new { Message = "유효하지 않은 심사관 토큰입니다." },
                    statusCode: 401);
            }

            try
            {
                await connection.OpenAsync();

                // 심사관 피드: Active 쇼츠를 최신순으로 10개 반환 (랭킹 무시)
                string sql = @"
                    SELECT id, text_content, custom_buttons, total_votes, bgm_id, created_at
                    FROM Shorts
                    WHERE status = 'Active'
                    ORDER BY created_at DESC
                    LIMIT 10";

                using var command = new MySqlCommand(sql, connection);
                using var reader = await command.ExecuteReaderAsync();
                var sandboxList = new List<object>();

                while (await reader.ReadAsync())
                {
                    sandboxList.Add(new
                    {
                        Id = reader.GetInt64("id"),
                        Text = reader.GetString("text_content"),
                        Buttons = reader.GetString("custom_buttons"),
                        Votes = reader.GetInt32("total_votes"),
                        BgmId = reader.IsDBNull(reader.GetOrdinal("bgm_id")) ? null : reader.GetString("bgm_id"),
                        CreatedAt = reader.GetDateTime("created_at")
                    });
                }

                return Results.Ok(new
                {
                    IsAuditMode = true,
                    Feed = sandboxList
                });
            }
            catch (Exception ex)
            {
                return Results.Problem(ex.Message);
            }
        });

        // ========================================================
        // [API 8] 심사관 1클릭 블라인드 (POST /api/shorts/admin/blind)
        // UC09 기본흐름 8~9: 누적 신고 임계치 생략, 즉시 Blind 처리
        // ========================================================
        group.MapPost("/admin/blind", async (AdminBlindRequest req, MySqlConnection connection) =>
        {
            // 토큰 유효성 검증
            if (!_activeAuditTokens.Contains(req.AuditToken))
            {
                return Results.Json(
                    new { Message = "유효하지 않은 심사관 토큰입니다." },
                    statusCode: 401);
            }

            try
            {
                await connection.OpenAsync();

                // 임계치 검사 없이 즉시 Blind 처리 (UC09 기본흐름 8)
                string sql = "UPDATE Shorts SET status = 'Blind' WHERE id = @shortsId AND status = 'Active'";
                using var cmd = new MySqlCommand(sql, connection);
                cmd.Parameters.AddWithValue("@shortsId", req.ShortsId);
                int affected = await cmd.ExecuteNonQueryAsync();

                if (affected == 0)
                {
                    return Results.NotFound(new { Message = "대상 쇼츠가 존재하지 않거나 이미 블라인드 처리되었습니다." });
                }

                // UC09 기본흐름 9: 블라인드 완료 안내
                return Results.Ok(new { Message = "관리자 권한으로 즉시 블라인드 처리되었습니다." });
            }
            catch (Exception ex)
            {
                return Results.Problem(ex.Message);
            }
        });
    }
}

// 클라이언트에서 받아올 데이터 껍데기(DTO)
public record ShortRequest(string CreatorUuid, string LanguageCode, string TextContent, string CustomButtons, string? BgmId);
public record VoteRequest(long ShortsId, int ButtonIndex, string VoterUuid);
public record ReportRequest(long ShortsId, string ReporterUuid);

// 심사관 모드 DTO (UC09)
public record AdminLoginRequest(string SecretCode);
public record AdminBlindRequest(long ShortsId, string AuditToken);

public class ButtonDto
{
    public int index { get; set; }
    public string text { get; set; } = "";
    public int votes { get; set; }
}