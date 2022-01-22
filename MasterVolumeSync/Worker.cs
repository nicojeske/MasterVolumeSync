using MasterVolumeSync.Helper;
using NAudio.CoreAudioApi;

namespace MasterVolumeSync
{
    public class Worker : BackgroundService
    {
        private static MMDeviceEnumerator enumer = new();

        private MMDevice WhatUHearDevice;
        private MMDevice masterVolumeDevice;
        private NotifyIcon notifyIcon;

        private ToolStripMenuItem mastervolumeMenuItem;
        private ToolStripMenuItem whatuhearMenuItem;

        private readonly IWritableOptions<Settings> _settings;
        private readonly ILogger<Worker> _logger;


        public Worker(IWritableOptions<Settings> settings, ILogger<Worker> logger)
        {
            _settings = settings;
            _logger = logger;

            logger.LogInformation("Worker created");
        }

        private void Run()
        {
            if (string.IsNullOrEmpty(_settings.Value.WhatUHearId))
            {
                MMDevice? possibleRec = enumer.EnumerateAudioEndPoints(DataFlow.Capture, DeviceState.Active)
                    .FirstOrDefault(x => x.FriendlyName.ToLower().Contains("sound blaster"));
                WhatUHearDevice = possibleRec ?? enumer.GetDefaultAudioEndpoint(DataFlow.Capture, Role.Multimedia);
            }
            else
            {
                WhatUHearDevice = enumer.GetDevice(_settings.Value.WhatUHearId);
            }

            masterVolumeDevice = string.IsNullOrEmpty(_settings.Value.OutputId)
                ? enumer.GetDefaultAudioEndpoint(DataFlow.Render, Role.Multimedia)
                : enumer.GetDevice(_settings.Value.OutputId);


            SaveDevicesInSettings();

            // Run showtrayicon in a separate thread
            var thread = new Thread(ShowTrayIcon);
            thread.IsBackground = false;
            thread.Start();

            masterVolumeDevice.AudioEndpointVolume.OnVolumeNotification += OnVolumeNotification;
        }

        private void ShowTrayIcon()
        {
            notifyIcon = new();
            notifyIcon.Text = "Master Volume Sync";
            notifyIcon.Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);

            notifyIcon.ContextMenuStrip = new();

            mastervolumeMenuItem = AudioDeviceSelection("Output device", enumer.EnumerateAudioEndPoints(DataFlow.Render, DeviceState.Active), SelectOutputDevice, masterVolumeDevice.ID);
            whatuhearMenuItem = AudioDeviceSelection("What U Hear device", enumer.EnumerateAudioEndPoints(DataFlow.Capture, DeviceState.Active), SelectWhatUHearDevice, WhatUHearDevice.ID);
            notifyIcon.ContextMenuStrip.Items.Add("Exit", null, Exit);


            notifyIcon.Visible = true;

            Application.Run();
        }

        private ToolStripMenuItem AudioDeviceSelection(string label, MMDeviceCollection audioDevices, EventHandler onClick, string currentDeviceId)
        {
            ToolStripLabel stripLabel = new ToolStripLabel(label);
            stripLabel.Font = new Font(stripLabel.Font, FontStyle.Bold);
            notifyIcon.ContextMenuStrip.Items.Add(stripLabel);

            ToolStripMenuItem activeItem = null;
            
            // Add every audio device to the context menu
            foreach (MMDevice? device in audioDevices)
            {
                ToolStripMenuItem item = new(device.FriendlyName);
                item.Tag = device.ID;
                item.Click += onClick;
                notifyIcon.ContextMenuStrip.Items.Add(item);
                if (device.ID == currentDeviceId)
                {
                    item.Checked = true;
                    activeItem = item;
                }
            }

            notifyIcon.ContextMenuStrip.Items.Add("-");
            return activeItem;
        }

        private void SelectOutputDevice(object? sender, EventArgs e)
        {
            // Register OnVolumeNotification to selected renderer
            masterVolumeDevice.AudioEndpointVolume.OnVolumeNotification -= OnVolumeNotification;
            masterVolumeDevice = enumer.GetDevice(((ToolStripMenuItem) sender).Tag.ToString());
            masterVolumeDevice.AudioEndpointVolume.OnVolumeNotification += OnVolumeNotification;

            uncheckOldAndCheckNewItem(sender, mastervolumeMenuItem);
            SaveDevicesInSettings();
        }

        private void SelectWhatUHearDevice(object? sender, EventArgs e)
        {
            WhatUHearDevice = enumer.GetDevice(((ToolStripMenuItem) sender).Tag.ToString());

            uncheckOldAndCheckNewItem(sender, whatuhearMenuItem);
            SaveDevicesInSettings();
        }

        private void SaveDevicesInSettings()
        {
            _settings.Update(opt =>
            {
                opt.OutputId = masterVolumeDevice.ID;
                opt.WhatUHearId = WhatUHearDevice.ID;
            });
        }

        private void uncheckOldAndCheckNewItem(object? sender, ToolStripMenuItem previousItem)
        {
            previousItem.Checked = false;
            ((ToolStripMenuItem) sender).Checked = true;
        }

        private void Exit(object? sender, EventArgs e)
        {
            notifyIcon.Visible = false;

            // https://stackoverflow.com/questions/14723843/notifyicon-remains-in-tray-even-after-application-closing-but-disappears-on-mous
            while (notifyIcon.Visible)
            {
                Application.DoEvents();
            }

            notifyIcon.Icon.Dispose();
            notifyIcon.Dispose();
            Application.Exit();
            Environment.Exit(0);
        }

        private void OnVolumeNotification(AudioVolumeNotificationData data)
        {
            // Adjust audio volume of the "What u hear" device
            WhatUHearDevice.AudioEndpointVolume.MasterVolumeLevelScalar = data.MasterVolume;
        }

        protected override Task ExecuteAsync(CancellationToken stoppingToken)
        {
            this.Run();
            return Task.CompletedTask;
        }
    }
}