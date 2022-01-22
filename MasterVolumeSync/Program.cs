using MasterVolumeSync;

var host = Host.CreateDefaultBuilder(args)
    .ConfigureServices((context, services) => { services.AddHostedService<Worker>(); })
    .Build();

await host.RunAsync();