{
  system.defaults = {
    ActivityMonitor = {
      # 0 => Application Icon
      # 2 => Network Usage
      # 3 => Disk Activity
      # 5 => CPU Usage
      # 6 => CPU History
      IconType = 5;
      OpenMainWindow = true;
      # 100 => All Processes
      # 101 => All Processes, Hierarchally
      # 102 => My Processes
      # 103 => System Processes
      # 104 => Other User Processes
      # 105 => Active Processes
      # 106 => Inactive Processes
      # 107 => Windowed Processes
      ShowCategory = 100;
      SortColumn = "CPUUsage";
      # 0 => descending
      SortDirection = 0;
    };

    NSGlobalDomain = {
      NSDisableAutomaticTermination = true;
    };
  };
}
