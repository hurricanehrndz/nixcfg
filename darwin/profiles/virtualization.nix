{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    docker-client
    docker-compose
    colima
    qemu
  ];
}
