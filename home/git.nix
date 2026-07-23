{ config, ... }:

{
  programs.git = {
    enable = true;

    # Home Manager 25.11: userName/userEmail/extraConfig were renamed into
    # `settings` (mkRenamedOptionModule). signing.key/signByDefault are unchanged.
    settings = {
      user.name = "Jitu";
      user.email = "jitumaat@protonmail.com";

      gpg.format = "ssh";

      init.defaultBranch = "main";
      pull.rebase = true;

      core = {
        autocrlf = false;
        editor = "nvim";
      };

      diff.tool = "nvim";
      difftool = {
        prompt = false;
        nvim.cmd = "nvim -d $LOCAL $REMOTE";
      };

      merge = {
        tool = "diffview";
        conflictStyle = "zdiff3";
      };
      mergetool = {
        prompt = false;
        diffview.cmd = ''nvim -c "DiffviewOpen"'';
        nvim.cmd = ''nvim -d $LOCAL $REMOTE $MERGED -c "wincmd J"'';
      };
    };

    signing = {
      key = "${config.home.homeDirectory}/.ssh/id_ed25519";
      signByDefault = true;
    };
  };
}