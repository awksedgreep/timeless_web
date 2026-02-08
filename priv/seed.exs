# Seed data for Timeless development
#
# Run with: mix run priv/seed.exs

store = Application.get_env(:timeless_web, :timeless_store, :metrics)

IO.puts("Seeding Timeless store #{inspect(store)}...")

# Register metrics
Timeless.register_metric(store, "cpu_usage", :gauge, unit: "%", description: "CPU utilization")
Timeless.register_metric(store, "mem_usage", :gauge, unit: "%", description: "Memory utilization")
Timeless.register_metric(store, "disk_io", :gauge, unit: "MB/s", description: "Disk I/O throughput")
Timeless.register_metric(store, "http_requests", :counter, unit: "req", description: "HTTP request count")
Timeless.register_metric(store, "response_time", :gauge, unit: "ms", description: "Response latency")

now = System.os_time(:second)
hosts = ["web-1", "web-2", "web-3"]

# Write 2 hours of data at 60s intervals
for offset <- 0..119 do
  ts = now - (119 - offset) * 60

  for host <- hosts do
    # CPU: 30-80% with some variation per host
    base_cpu = case host do
      "web-1" -> 45.0
      "web-2" -> 55.0
      "web-3" -> 35.0
    end
    cpu = base_cpu + :rand.uniform() * 30 - 15
    Timeless.write(store, "cpu_usage", %{"host" => host}, cpu, timestamp: ts)

    # Memory: 50-90%
    mem = 60.0 + :rand.uniform() * 25 + offset * 0.05
    Timeless.write(store, "mem_usage", %{"host" => host}, min(mem, 95.0), timestamp: ts)

    # Disk I/O: 10-100 MB/s
    disk = 30.0 + :rand.uniform() * 50
    Timeless.write(store, "disk_io", %{"host" => host}, disk, timestamp: ts)

    # HTTP requests: 100-500 per interval
    reqs = 200.0 + :rand.uniform() * 300
    Timeless.write(store, "http_requests", %{"host" => host}, reqs, timestamp: ts)

    # Response time: 10-200ms
    rt = 50.0 + :rand.uniform() * 100
    Timeless.write(store, "response_time", %{"host" => host}, rt, timestamp: ts)
  end
end

IO.puts("Wrote metric data for #{length(hosts)} hosts over 2 hours")

# Flush and roll up
Timeless.flush(store)
Timeless.rollup(store)

# Create alerts
Timeless.create_alert(store,
  name: "High CPU",
  metric: "cpu_usage",
  condition: :above,
  threshold: 80.0,
  duration: 300,
  aggregate: :avg
)

Timeless.create_alert(store,
  name: "High Memory",
  metric: "mem_usage",
  condition: :above,
  threshold: 90.0,
  duration: 0,
  aggregate: :last
)

Timeless.create_alert(store,
  name: "Slow Responses",
  metric: "response_time",
  condition: :above,
  threshold: 150.0,
  duration: 600,
  aggregate: :avg
)

IO.puts("Created 3 alert rules")

# Evaluate alerts to populate states
Timeless.evaluate_alerts(store)

# Create annotations
Timeless.annotate(store, now - 3600, "Deploy v2.1.0",
  description: "Rolled out new caching layer",
  tags: ["deploy", "production"]
)

Timeless.annotate(store, now - 1800, "Config change",
  description: "Increased worker pool size from 10 to 20",
  tags: ["config"]
)

Timeless.annotate(store, now - 600, "Incident resolved",
  description: "Memory spike on web-2 cleared after GC",
  tags: ["incident", "resolved"]
)

IO.puts("Created 3 annotations")

info = Timeless.info(store)
IO.puts("\nStore info:")
IO.puts("  Series: #{info.series_count}")
IO.puts("  Points: #{info.total_points}")
IO.puts("  Storage: #{info.storage_bytes} bytes")
IO.puts("\nDone! Start the server with: mix phx.server")
