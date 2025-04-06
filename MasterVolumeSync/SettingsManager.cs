﻿using System.Reflection;

namespace MasterVolumeSync;

public abstract class SettingsManager<T> where T : SettingsManager<T>, new()
{
    private static readonly string filePath = GetLocalFilePath($"{typeof(T).Name}.json");

    public static T Instance { get; private set; }

    private static string GetLocalFilePath(string fileName)
    {
        string appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        var companyName = Assembly.GetEntryAssembly().GetCustomAttributes<AssemblyCompanyAttribute>().FirstOrDefault();
        return Path.Combine(appData, companyName?.Company ?? Assembly.GetEntryAssembly().GetName().Name, fileName);
    }

    public static void Load()
    {
        if (File.Exists(filePath))
            Instance = System.Text.Json.JsonSerializer.Deserialize<T>(File.ReadAllText(filePath));
        else
            Instance = new T();
    }

    public static void Save()
    {
        string json = System.Text.Json.JsonSerializer.Serialize(Instance);
        Directory.CreateDirectory(Path.GetDirectoryName(filePath));
        File.WriteAllText(filePath, json);
    }
}