
with AWS.MIME;
with AWS.Parameters;
with Ada.Characters.Handling;
with AWS.Templates;
with AWS.Translator;

with Ada.Text_IO;
use Ada;

package body Home_Page is

   WWW_Root : constant String := "www_data";
  
    overriding function Clone (Element : in Home_Page_Handler) return Home_Page_Handler is
    begin
      return Element;
    end Clone;

    overriding function Dispatch
     (Handler : in Home_Page_Handler;
      Request : in Status.Data) return Response.Data
    is
      URI : constant String := Status.URI (Request);
    begin
      Ada.Text_IO.Put_Line("Used Home_Page asking for " & URI);
      return Response.Build
       ("text/html", String'(Templates.Parse (WWW_Root & "/index.thtml")));
    end Dispatch;

end Home_Page;
