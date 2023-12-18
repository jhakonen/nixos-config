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
  kota-portti =
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD3zbvY+UeRbzSGnti3y9I0CFb5LB9ckPv"
    + "vq45Il7UrNE7omEnehv4LBhVarCcU6iY6wpzxXXb/1gCOM27Hf1Da7TpohEyeb05Q8N52"
    + "GwCPUOvUqmE1x9lxiwLSWMONili8Sk5/ZB8F9VZ5uIzkIdnZ0OhgWba7pYRWXkGmXcGuT"
    + "48iaCxXD7VoUHpbL4CmMQVWwgFBjhhZyDFJoCQaBjseAZmbXe+QuLf0lyfqi4yxub8m6T"
    + "hG2NN6XKBp0Rqw7vy2Gfab8dIt3nwuEivRahuGf/G2bW2FpEkVFtzSUx2xchR5QX55u4K"
    + "kCmJCGaYSxlEI8robiAGIQYYsTAgLgQKvZXow2xngIA/dtuhG/4n4A5QhJuvDuMuLxWsg"
    + "gXHNmCRrBhHDXQkBvXZp1PE4b/dwwuL/61J+Y2LxBy3i3rQXf/UyeJh2xLvf4KvWzB7HF"
    + "/WQqfWmnQOr0dR/+Qz1lz3kxEwAO9Sdt5O9mXHE/ig+aaPEfIXGxB+zidonjNHGSaRCOF"
    + "MrGiDiuj1N/FQshT2/t84ITkU3Ji6uZbh1G1iPlPtd62QQVLNM/3apC71+6+JRJNEkeJa"
    + "M65P3ZC16x4OtQ67tl4aIk6nUsynxge4QyaFMK7Que1mDpskBdmIbkvrRVGey5PbjPgnm"
    + "+FJ1QHTSnbWPESrPDIyboTEAzAc7tQ== root@nixos";
  mervi =
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3uO0vRYsRkzSafCqYQ3m9nPTiiNW/z/T"
    + "qAuUy19vhI/6t3fxZ9lTdkBUrtTsXEYqk72xOaMTcnbyE87Y7AXFt25VG2mHybJq88OI5"
    + "6Nh82XRSM7Ls+YG4k1xs/FPWbOXlrfzDaVAiFdyd2qsMaZpc3dhe6DwrKfgkzcFGRNXkF"
    + "dAyS2I2AULinAFQAIyGg1p2BWX4K8z/zaLZrXA7BjkxULV8YVPWZrkPRgL2pp1uddk8NL"
    + "UUf883Mtx/y2S5wCPjVchCBqSyEsiJFg8JUhTIcl3LpQcfK8KY2j/YFjcKDVWGz1+ajps"
    + "C3omCpaXya+BHwFbugtbsdf+x49Pd4axslg+MAUa6jf/aXNQRueCcQZ7KdIbTmnM7sVpQ"
    + "MIHcZniz9U5/IyWbl5LCcAVL64B14WrO3YeC/ZC2TNmKEF/hybNAVEwpN65QtnES5SIW8"
    + "oKJvGo1SvMFaCljpn/jdv2mWvZlCMuBGAJ0l+R4O+A8OkMdI2ni8Cee/G1Zr3rk6hZVSF"
    + "F1tjXKPyIvwRaqPky8tiE507FF5FHh75ourWNTmC5GArU0AGYVXhqZa9Z71IxBcPtHTqc"
    + "RgyuiBdfnbNyJ83/6TJ27OZV33ZP8NkbT8avh9nCdelsPghndEux3sf1mINqGOFltdtuD"
    + "0UPFY3z6hq1tzpwkE3PSjEFX4/lzOw== root@mervi";
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
in
{
  "acme-joker-credentials.age".publicKeys = [ jhakonen nas-toolbox ];
  "borgbackup-id-rsa.age".publicKeys = [ jhakonen kota-portti nas-toolbox ];
  "borgbackup-password.age".publicKeys = [ jhakonen kota-portti nas-toolbox ];
  "bt-mqtt-gateway-environment.age".publicKeys = [ jhakonen kota-portti ];
  "github-id-rsa.age".publicKeys = [ jhakonen nas-toolbox ];
  "mqtt-password.age".publicKeys = [ jhakonen nas-toolbox kota-portti mervi ];
  "mqttwarn-environment.age".publicKeys = [ jhakonen nas-toolbox ];
  "node-red-environment.age".publicKeys = [ jhakonen nas-toolbox ];
  "telegraf-environment.age".publicKeys = [ jhakonen nas-toolbox ];
  "vaultwarden-environment.age".publicKeys = [ jhakonen nas-toolbox ];
  "zigbee2mqtt-environment.age".publicKeys = [ jhakonen kota-portti ];
}
