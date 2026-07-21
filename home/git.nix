{ config, ... }:

{
  programs.git = {
    enable = true;
    userName = "Jitu";
    userEmail = "jitumaat@protonmail.com";

    signing = {
      key = "${config.home.homeDirectory}/.ssh/id_ed25519";
      signByDefault = true;
    };

    extraConfig = {
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
  };
}
