{
  editorconfig.enable = true;
  editorconfig.settings = {
    "*" = {
      charset = "utf-8";
      trim_trailing_whitespace = true;
      insert_final_newline = true;
      end_of_line = "lf";
      max_line_width = 78;
      indent_style = "space";
      indent_size = 4;
    };
    "*.py" = {
      max_line_length = 119;
    };
    "*.pp" = {
      max_line_length = 140;
      indent_size = 2;
    };
    "*.lua" = {
      max_line_length = 119;
      indent_size = 2;
    };
    "*.nix" = {
      max_line_length = 119;
      indent_size = 2;
    };
    "*.go" = {
      indent_style = "tab";
    };
    "*.plist" = {
      indent_style = "tab";
    };
    "Makefile" = {
      indent_style = "tab";
    };
    "*.md" = {
      trim_trailing_whitespace = false;
    };
    "*.{yaml,yml}" = {
      indent_size = 2;
      max_line_length = 120;
    };

  };
}
