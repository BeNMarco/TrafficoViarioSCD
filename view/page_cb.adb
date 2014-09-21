with Ada.Strings.Unbounded;
with Ada.Directories; 
with Ada.Text_IO;
with Ada.Strings.Fixed;

with AWS.MIME;
with AWS.Parameters;
with AWS.Messages;
with AWS.Dispatchers;
with AWS.Templates;

with Templates_Parser;


use Ada;
use Ada.Strings.Fixed;

package body Page_CB is

  use Ada.Strings.Unbounded;
  use Ada.Directories;
  use Ada.Text_IO;

    WWW_Root : String := "www_data";

    overriding function Clone (Element : in District_Page) return District_Page is
    begin
      return Element;
    end Clone;

    -- overriding procedure Finalize (This : in out District_Page) is
    -- begin
    --   -- Put_Line("Finalizing Id " & Natural'Image(This.Id) & " Num " & Integer'Image(Num));
    --   -- Finalize((This)District_Page);
    --   --AWS.Dispatchers.Handler(This).Finalize;
    -- end Finalize;

    -- overriding procedure Initialize (This : in out District_Page)  is
    -- begin 
    --   Num := Num +1;
    -- end Initialize;

    procedure Init(This : in out District_Page; I : Natural; D : String) is
      JSON_File : File_Type;
      -- TmpID : String := Natural'Image(I);
      -- StringID : String := TmpID(TmpID'First+1 .. TmpID'Last); 
      StringID : String := Trim(Natural'Image(I), Ada.Strings.Left);
    begin
      This.Id := I;
      This.JSON_File_Name := To_Unbounded_String("quartiere" & StringID & ".json");
      -- Put_Line("Writing " & D & " in " & To_String(This.JSON_File_Name));
      Create(File => JSON_File, Mode => Out_File, Name => WWW_Root & "/" & To_String(This.JSON_File_Name));
      Put_Line(JSON_File, D);
      Close(JSON_File);
      This.Initialized := True;
    end Init;

    procedure Clean(This : in out District_Page) is
    begin
      -- Put_Line("My file is " & To_String(This.JSON_File_Name));
      if This.Initialized then
        Delete_File(To_String(This.JSON_File_Name));
      end if;      
    end Clean;

    overriding function Dispatch
     (This : in District_Page;
      Request : in Status.Data) return Response.Data
    is
      URI : constant String := AWS.Status.URI (Request);
      Filename : constant String := URI (2 .. URI'Last);
      URI_Root : constant String := "/quartiere" & This.String_ID;
    begin
      if URI = URI_Root & "/map.json" then
        declare
          JSON_File_Dir : String := WWW_Root & "/" & To_String(This.JSON_File_Name);
        begin
          return
            AWS.Response.File
              (Content_Type => AWS.MIME.Content_Type (JSON_File_Dir),
              Filename => JSON_File_Dir);
        end;
      else
        declare
          T : constant Templates_Parser.Translate_Table :=
            (1 => Templates_Parser.Assoc("ID_QUARTIERE", This.String_ID));
        begin
          return Response.Build
           ("text/html", String'(Templates.Parse (WWW_Root & "/quartiere.thtml", T)));
        end;
        -- return AWS.Response.Acknowledge
        --  (Messages.S404, "<p>Page '" & URI & "' Not found.");
      end if;
    end Dispatch;

    function Is_Initialized(This : in District_Page) return Boolean is
    begin
      return This.Initialized;
    end Is_Initialized;

    function String_ID (This : in District_Page) return String is
    begin
      return Trim(Natural'Image(This.ID), Ada.Strings.Left);
    end String_ID;

end Page_CB;
