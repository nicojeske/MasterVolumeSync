using MasterVolumeSync;
using MasterVolumeSync.Helper;
using Newtonsoft.Json;

// If appsettings.json is not found, it will be created with the default values.
// To change the default values, edit the appsettings.json file.
if (!File.Exists(Path.Combine(AppContext.BaseDirectory, "appsettings.json")))
{
    File.WriteAllText(Path.Combine(AppContext.BaseDirectory, "appsettings.json"),
        JsonConvert.SerializeObject(new
        {
            Settings = new Settings()
        }, Formatting.Indented));
}

var host = Host.CreateDefaultBuilder(args)
    .ConfigureServices((context, services) =>
    {
        services.AddHostedService<Worker>();
        services.ConfigureWritable<Settings>(context.Configuration.GetSection("Settings"));
    })
    
    .Build();

await host.RunAsync();