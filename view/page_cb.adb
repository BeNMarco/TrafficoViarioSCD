
with AWS.MIME;
with AWS.Parameters;
with AWS.Messages;
--with OS_Lib;

with Ada.Text_IO;
use Ada;

package body Page_CB is

    function Provide_Home_Page (Request : Status.Data) 
      return Response.Data 
    is
      URI : constant String := AWS.Status.URI (Request);
      Filename : constant String := URI (2 .. URI'Last);
      Directory_Prefix : constant String := "www_data";
    begin
      if 1 = 1 then
        return
          AWS.Response.File
            (Content_Type => AWS.MIME.Content_Type (Directory_Prefix & Filename),
            Filename => Directory_Prefix & Filename);
      else
        return AWS.Response.Acknowledge
          (Messages.S404, "<p>Page '" & URI & "' Not found.");
      end if;
    end Provide_Home_Page;
  
    overriding function Clone (Element : in Static_Page) return Static_Page is
    begin
      return Element;
    end Clone;

    procedure Set_Data(Handler : in out Static_Page; D : String) is
    begin
      Text_IO.Put_Line("set_data in" & D);
      -- Handler.Data := D;
      -- Handler.Data := (others => ' ');
      Text_IO.Put_Line("set_data out");
    end Set_Data;

    procedure Set_Id(Handler : in out Static_Page; I : Natural) is
    begin
      Handler.Id := I;
    end Set_Id;

    overriding function Dispatch
     (Handler : in Static_Page;
      Request : in Status.Data) return Response.Data
    is
      URI : constant String := AWS.Status.URI (Request);
      Filename : constant String := URI (2 .. URI'Last);
      Directory_Prefix : constant String := "www_data";
    begin
      if 1 = 1 then
        return
          AWS.Response.File
            (Content_Type => AWS.MIME.Content_Type (Directory_Prefix & Filename),
            Filename => Directory_Prefix & Filename);
      else
        return AWS.Response.Acknowledge
          (Messages.S404, "<p>Page '" & URI & "' Not found.");
      end if;
    end Dispatch;

end Page_CB;
