{ lib, pkgs, ... }:

{
  home.packages = builtins.map (
    name: lib.attrByPath (lib.splitString "." name) (throw "Unknown extra package: ${name}") pkgs
  ) (builtins.fromJSON (builtins.readFile ./extra-packages.json));
}
