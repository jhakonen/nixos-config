let
  # ~/.ssh/id_rsa.pub
  jhakonen =
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDMqorF45N0aG+QqJbRt7kRcmXXbsgvXw7"
    + "+cfWuVt6JKLLLo8Tr7YY/HQfAI3+u1TPo+h7NMLfr6E1V3kAHt7M5K+fZ+XYqBvfHT7F8"
    + "jlEsq6azIoLWujiveb7bswvkTdeO/fsg+QZEep32Yx2Na5//9cxdkYYwmmW0+TXemilZH"
    + "l+mVZ8PeZPj+FQhBMsBM+VGJXCZaW+YWEg8/mqGT0p62U9UkolNFfppS3gKGhkiuly/kS"
    + "KjVgSuuKy6h0M5WINWNXKh9gNz9sNnzrVi7jx1RXaJ48sx4BAMJi1AqY3Nu50z4e/wUoi"
    + "AN7fYDxM/AHxtRYg4tBWjuNCaVGB/413h46Alz1Y7C43PbIWbSPAmjw1VDG+i1fOhsXnx"
    + "cLJQqZUd4Jmmc22NorozaqwZkzRoyf+i604QPuFKMu5LDTSfrDfMvkQFY9E1zZgf1LAZT"
    + "LePrfld8YYg/e/+EO0iIAO7dNrxg6Hi7c2zN14cYs+Z327T+/Iqe4Dp1KVK1KQLqJF0Hf"
    + "907fd+UIXhVsd/5ZpVl3G398tYbLk/fnJum4nWUMhNiDQsoEJyZs1QoQFDFD/o1qxXCOo"
    + "Cq0tb5pheaYWRd1iGOY0x2dI6TC2nl6ZVBB6ABzHoRLhG+FDnTWvPTodY1C7rTzUVyWOn"
    + "QZdUqOqF3C79F3f/MCrYk3/CvtbDtQ== jhakonen";
  # /etc/ssh/ssh_host_rsa_key.pub
  nas-toolbox =
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDk2VrBOGh0UgaztWOSZVqoNEdzQeObWba"
    + "D/7czbc11zxrr0AhyrpcYC8rA4LPijE//hymsR/ofM06xBN/cducebTbkaMda7JykVSwD"
    + "ZCgA3gLlyp36n+Moh7s0rVMof4sVFr8KXH6TCpax7MgepFrvEtv/TkCrC3e4fcL4cmqL/"
    + "j4eJSfipBLVXHmOcHqDW069wH5JwYBq5Kxzzoyrsvuo5V9UuZQNseSWpQcZanAtYuo94A"
    + "AAE+ADtqh9N4Va67x/cTKY0DGnHGXVI4TId+IBleQtmqPCaz2TVROgSWjiPqP4N433ZEZ"
    + "Rlf6F2UFA0V0N0xUKy6F7YuWujZYCHsleLwgVy8h+/BVOR5GwOj3GuJ70P4Oe6XCxOLkV"
    + "U6RdPo7zLuPHJv2H10HX0xT9r8NkVeh2+CN3SkLf9nWvfn12u2cW5WFKtKHs5GVNby536"
    + "g9Ebj30rbC3eg8s7D1bivcweotRwzt/vc6Ef8GE76joH2DJhIJSmU7PFbFVCC/566HIxJ"
    + "4u6xD2QnrZCIgKDW9JbbMNJZWDGerDltdh6SpjQjIizuzla+hloY+vp2cw2iMN9o6jXbG"
    + "H2ogrsIKXHyEaOJ9jjdTmngvbrXNalcIpBK3oGj6pvPR+y3ayEZ6fMWXlZ9aLkRM3oIdq"
    + "XUb80pgeh/stpeOv2canemQHzUHZ6Q== root@nas-toolbox";
  keys = [ jhakonen nas-toolbox ];
in
{
  "borgbackup-id-rsa.age".publicKeys = keys;
  "borgbackup-password.age".publicKeys = keys;
  "environment-variables.age".publicKeys = keys;
  "github-id-rsa.age".publicKeys = keys;
  "mqtt-password.age".publicKeys = keys;
  "vaultwarden-environment.age".publicKeys = keys;
  "wildcard-jhakonen-com.key.age".publicKeys = keys;
}
