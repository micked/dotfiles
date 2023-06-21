let
  msk-oblivion = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAl2CucKeMdT7rx4067EBk8VALHCsteFzMHdqA0+nETs";
  users = [ msk-oblivion ];

  oblivion = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA+77ql7Xd2lZHGicawue0wO28mJpDOnTi+QR/JUvLql";
in
{
  "oblivion_nixkey.age".publicKeys = [ msk-oblivion oblivion ];
}
