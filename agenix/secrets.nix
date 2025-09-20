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
  kanto =
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDH+rO7H/8VWPzFHgKnndP4+WG5fA9loJR"
    + "QFxOMu1/+qTXhTKyZZcbKa2hnXQB7p0Xm90/NFGarQsWt4mdXRoS+Alx09zXsllDqowj6"
    + "q+KT20xUVOatJ6oB4afgVsH13+BgBhpt/9EpsH+AGAGgpPJzkpieobxnbOBv//4FGR7TO"
    + "O/Cuy2mWOlV4XEgFhGcQQaD/Aec7tfSUi1AEcpntusLOU8PZe+XparHpveH88Q5/IZqsp"
    + "n1F3+Ka3ONgv04571tWXlM8BHwWnfKynGs7AcnmMGT+S7OIaR1FF1Iil/ufys4IbRF80d"
    + "It4CsgdzSqcMc+OBV6wx4aFvFvK9mRLYxnzEIamDOSTAq2yS0jjo0BmNQhxuTS9HGaPHr"
    + "dZUv3heWIynjBDzmuOY5JNbAQ9f9LVPFtKFbAmWMhLEGo5VfELphwgkeBbCO1QtuH6jeN"
    + "Z8j1ylPvlEOBuRKNlsOlZzDx0ut0u1gdoZiRtt7W5PsMg/nDlKn1Ftd14U0/A5eKSd1+B"
    + "YGid7tJStPRpKYsxKkAShyX1HUNpYCLv4VqweTtHiL33qZwRTl9+BkgjAMM+Wmo5IWKTx"
    + "T7hmDLwuXbquOmvck2VcZqw1XnGnjSY/2fYtHvH18UYdH4fTCIF+0afMoZYdDAHmSIW8P"
    + "lIX3PDzHa4RLMXR6ZXQPs5tyxMozow== root@kanto";
  # /etc/ssh/ssh_host_rsa_key.pub
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
  toukka =
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCZ0CXyDc1+ro40OnaWymLtPzGW2jWglRr"
    + "MLsFzwTE9ufd4V14Yn3yAWzs8xqv/5kRJk/s8W4LqlMrf1Y8g6effuML12kY95vYDfBq6"
    + "UFE58HhlTEkHxaNQo4RWdwwS4kRvkAZz47OYeb8oBjZAVeQQkuE1R19LdFfy1vqaEZYWv"
    + "2/+PpzjHxtkr8FB5j+UR6jqo4G0dqRa4HobMwzG38bQZk63ULtbZwBZtbt1W+lh1Gdnmj"
    + "rMd/mVbQe0ywC4WJjfRGRSn6tkvLpJbK9eDUQcspZhaYmfNBoy4rEDsTnF0XCekcEwDgX"
    + "WHIpk2EdmM05j+zfFym8S0etXboyGJtCJTOMDdIgmPjFS7F008dzVn2pF80GJTKRT9tUu"
    + "tpJ7fmDxisqajLlLnLQEjxmnnvNyKubcuJkTOpKe9QmmpE/Awl0YrNHb7FNASJ+Rizt7a"
    + "1wX04UE10lMCdtrm1lnBLk5vOsm7mrzqAgTLWj/sQOn9bys/niAtKakT8M6c7qWmAmhhH"
    + "EUyeKeazWk8GPMZM8uZGhwSqjn3r2S5MaoeugRhLw3JebK+VDBwmv35JvM+MC+zJpspya"
    + "9eN+KRbDlOsdYaSuFnlL7L37Wtbix8zWypnzjcv2EqIlxYA0Za78JEVA1oFApKacHFtU8"
    + "QHagpTS1GtFndNZ1Sw0V8CeleXm9uQ== root@toukka";
  # /etc/ssh/ssh_host_rsa_key.pub
  tunneli =
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDWGXpckdtgJqLMMT4xals2MN+goueB5H6"
    + "lDEvQko55kEyrYoTdJnl4rkFx2Kwyt/cb+kddXtKVGv1BSAqDCYAdcKjH6tGFi1C31sev"
    + "5WQetTzL4ksqxEthq29jGxLVhAhxoLHIUNpFU8PMPjm1/TjbRjZ7hsSBje9pxY7+m0Q7v"
    + "Mr+sWpogE0WLHaX32T0VsexRacYtva8LNUq8GRk7vWZWs7Ub/I8ysa/ZWeDGWAbbMUr3R"
    + "axxME8/R6IQPOjxaG51jjViecY3BEOBSjwDYgfkvsq/7BN2qO3+KU2n/WTpSY++CLR30A"
    + "Pwq5tPHXR2zTXPGNXnZRvOuel5h5iGkHwq3NpnNIVgcV09xnks4VpUhad+1ope9BI4+6P"
    + "Cyg5anmR0Ijja3BYiSKoal2vj2FIm04MTORx8lQF9JKbvJpA9n1AqA7lxzTrEshMWSB2J"
    + "gJgdM24ff3BQI0a4lWISj/+VkbDb2Osc23QBHNyO/tkLAetiluyeEIkAv6GebZ8S+YZJJ"
    + "Z8Ggt2bRT1K+sdMYsW2l7icopuCjIkvzjf4o6LuKwzeUCdP8rRNTyv8aDmFT9t/d+v7k2"
    + "NTXWK4Q+van2pObz4RYWRqmpysZZDg0oNUV42xQMTcSOGPH8bnfYU/v9vkisr0NzL3j4G"
    + "VqASH9sE/KgIT+FNOpAu4KwYdfgAbQ== root@tunneli";
in
{
  "acme-joker-credentials.age".publicKeys = [ jhakonen kanto mervi toukka tunneli ];
  "freshrss-admin-password.age".publicKeys = [ jhakonen kanto ];
  "github-id-rsa.age".publicKeys = [ jhakonen ];
  "karakeep-environment.age".publicKeys = [ jhakonen kanto ];
  "mqtt-password.age".publicKeys = [ jhakonen kanto mervi toukka ];
  "mqtt-espuser-password.age".publicKeys = [ jhakonen kanto ];
  "rsyncbackup-password.age".publicKeys = [ jhakonen kanto mervi toukka ];
  "telegraf-environment.age".publicKeys = [ jhakonen kanto ];
  "zigbee2mqtt-environment.age".publicKeys = [ jhakonen toukka ];
}
