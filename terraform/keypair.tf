# Utwórz Key Pair tylko gdy SSH jest włączone
resource "aws_key_pair" "this" {
  count      = var.ssh_cidr == "" ? 0 : 1
  key_name   = var.ssh_key_name
  public_key = file(var.public_key_path)
}
