using Npgsql;

namespace KekeBeauty.Web.Services;

public static class Database
{
    public static NpgsqlDataSource Create(IConfiguration configuration, IWebHostEnvironment environment)
    {
        var connection = configuration.GetConnectionString("KekeBeauty");
        if (string.IsNullOrWhiteSpace(connection) && environment.IsDevelopment())
        {
            var path = Path.GetFullPath(Path.Combine(environment.ContentRootPath, "../../infra/postgres/.env"));
            if (File.Exists(path))
            {
                var password = File.ReadLines(path).FirstOrDefault(x => x.StartsWith("POSTGRES_PASSWORD="))?[18..];
                if (!string.IsNullOrWhiteSpace(password))
                    connection = new NpgsqlConnectionStringBuilder
                    {
                        Host = "127.0.0.1", Port = 55432, Database = "keke_merise",
                        Username = "keke_owner", Password = password, IncludeErrorDetail = false
                    }.ConnectionString;
            }
        }
        if (string.IsNullOrWhiteSpace(connection))
            throw new InvalidOperationException("Configurer ConnectionStrings__KekeBeauty avant de démarrer.");
        return NpgsqlDataSource.Create(connection);
    }
}
