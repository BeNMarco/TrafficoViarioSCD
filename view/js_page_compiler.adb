
with AWS.MIME;
with AWS.Parameters;
with Ada.Characters.Handling;
with AWS.Templates;
with AWS.Translator;

with Ada.Text_IO;
use Ada;

package body JS_Page_Compiler is

   WWW_Root : constant String := "www_data";
  
    overriding function Clone (Element : in JS_Page_Compiler_Handler) return JS_Page_Compiler_Handler is
    begin
      return Element;
    end Clone;

    overriding function Dispatch
     (Handler : in JS_Page_Compiler_Handler;
      Request : in Status.Data) return Response.Data
    is
      URI : constant String := Status.URI (Request);
    begin
      Ada.Text_IO.Put_Line("Used JS_Page_Compiler asking for " & URI);
      return AWS.Response.Build
       (MIME.Text_Javascript,
        Message_Body => Templates.Parse
          (WWW_Root & "/js/aws" & URI (URI'First + 6 .. URI'Last)));
    end Dispatch;

end JS_Page_Compiler;
