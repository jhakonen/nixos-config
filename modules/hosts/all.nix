{ inputs, den, lib, ... }:
{
  imports = [ inputs.den.flakeModule ];
  # Ota Home Manager käyttöön
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];
  den.ctx.user.includes = [ den._.mutual-provider ];
}
