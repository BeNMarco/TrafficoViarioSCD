with AWS.MIME;
with AWS.Parameters;
with Ada.Characters.Handling;
with AWS.Templates;
with AWS.Translator;
with Ada.Text_IO;
with Districts_Repository;
with Templates_Parser;

with System;
with System.Address_Image;

use Ada;
use Districts_Repository;
use Templates_Parser;

package body Home_Page is

   WWW_Root : constant String := "www_data";
  
    overriding function Clone (This : in Home_Page_Handler) return Home_Page_Handler is
      To_Ret : Home_Page_Handler := This;
    begin
      return To_Ret;
    end Clone;

    procedure Set_Districts_Repository(This : in out Home_Page_Handler; R : Access_Districts_Repository_Interface) is
    begin
      This.Districts_Repository := R;
    end Set_Districts_Repository;

    overriding function Dispatch
     (This : in Home_Page_Handler;
      Request : in Status.Data) return Response.Data
    is
      use type Templates_Parser.Vector_Tag;

      URI : constant String := Status.URI (Request);

      Districts_ID : Vector_Tag;
      Registered  : Vector_Tag;

      R : Districts_Registry_Type := This.Districts_Repository.Get_Districts_Registry;

      T : Translate_Set;
    begin

      for I in R'Range loop
        Districts_ID := Districts_ID & I;
        Registered := Registered & R(I).Is_Initialized;
      end loop;

      Insert(T, Assoc("DISTRICT_ID", Districts_ID));
      Insert(T, Assoc("REG", Registered));

      return Response.Build
       ("text/html", String'(Templates.Parse (WWW_Root & "/index.thtml", T)));
    end Dispatch;

end Home_Page;
