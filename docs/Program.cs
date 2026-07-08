using DotNetEnv;
using MySqlConnector;
using AnonymousShortsApi; // 우리가 만든 네임스페이스 가져오기

var builder = WebApplication.CreateBuilder(args);

// .env 로드 및 정보 추출
Env.Load();
var dbHost = Environment.GetEnvironmentVariable("DB_HOST");
var dbPort = Environment.GetEnvironmentVariable("DB_PORT");
var dbUser = Environment.GetEnvironmentVariable("DB_USER");
var dbPass = Environment.GetEnvironmentVariable("DB_PASS");
var dbName = Environment.GetEnvironmentVariable("DB_NAME");

var connectionString = $"Server={dbHost};Port={dbPort};Database={dbName};User ID={dbUser};Password={dbPass};";

Console.WriteLine($"[System] DB 연결 준비 완료: Server={dbHost}; Database={dbName}");

// DI 컨테이너에 MySQL 등록
builder.Services.AddTransient<MySqlConnection>(_ => new MySqlConnection(connectionString));
builder.Services.AddOpenApi();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// 헬스 체크 API
app.MapGet("/health", async (MySqlConnection connection) =>
{
    try
    {
        await connection.OpenAsync();
        using var command = new MySqlCommand("SELECT 1;", connection);
        await command.ExecuteScalarAsync();
        return Results.Ok(new { Status = "Healthy", Database = "Connected" });
    }
    catch (Exception ex)
    {
        return Results.Json(new { Status = "Unhealthy", Error = ex.Message }, statusCode: 500);
    }
});


// 🔥 [핵심 주입] Shorts 엔드포인트를 허브에 연결합니다.
app.MapShortsEndpoints();

app.Run();