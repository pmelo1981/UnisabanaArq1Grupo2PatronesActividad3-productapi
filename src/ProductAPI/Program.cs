using ProductAPI.Models;
using ProductAPI.Repositories;
using StatsdClient;

var builder = WebApplication.CreateBuilder(args);

// Configurar métricas customizadas para Datadog
DogStatsd.Configure(new StatsdConfig
{
    StatsdServerName = Environment.GetEnvironmentVariable("DD_AGENT_HOST") ?? "127.0.0.1",
    StatsdPort = 8125,
});

// Agregar servicios
builder.Services.AddSingleton<ProductRepository>();
builder.Services.AddControllers();
// Habilitar generación de OpenAPI/Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Exponer OpenAPI y Swagger UI siempre
app.UseSwagger();
app.UseSwaggerUI();

app.UseHttpsRedirection();
app.MapControllers();

// Endpoint de health check
app.MapGet("/api/products/health", () => 
    Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }))
.WithName("HealthCheck");

app.Run();
