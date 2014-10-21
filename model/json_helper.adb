with Ada.Direct_IO;
with Ada.Directories;
with Ada.Text_IO;use Ada.Text_IO;

package body JSON_Helper is

   function Load_File(File_Name : String) return String is
      use Ada.Directories;
      File_Size    : constant Natural := Natural (Size (File_Name));

      subtype Test_JSON_Str is String (1 .. File_Size);
      package File_IO is new Ada.Direct_IO (Test_JSON_Str);

      File : File_IO.File_Type;
      String_Content : Test_JSON_Str;
   begin
      File_IO.Open (File => File, Mode => File_IO.In_File, Name => File_Name);
      File_IO.Read (File => File,Item => String_Content);
      File_IO.Close (File => File);
      return String_Content;
   end Load_File;

   function Get_Json_Value(Json_String : String := ""; Json_File_Name : String := "") return JSON_Value is
      Json : JSON_Value;
   begin
      if Json_String = "" then
         Json := Read (Strm => Load_File (Json_File_Name), Filename => "");
      elsif Json_File_Name = "" then
         Json := Read (Strm => Json_String, Filename => "");
      end if;
      return Json;
   end Get_Json_Value;

   procedure Handler(Name  : in UTF8_String;Value : in JSON_Value) is
      use Ada.Text_IO;
      bool_element : Boolean;
      int_element : Integer;
      float_element : Float;
      arr_element : JSON_Array;
   begin
      case Kind (Val => Value) is
      when JSON_Null_Type =>
         Put_Line (Name & ":null");
      when JSON_Boolean_Type =>
         bool_element := Get(Value);
         Put_Line (Name & ":" & Boolean'Image(bool_element));
      when JSON_Int_Type =>
         int_element := Get(Value);
         Put_Line (Name & ":" & Integer'Image(int_element));
      when JSON_Float_Type =>
         float_element := Get(Value);
         Put_Line (Name & ":" & Float'Image(float_element));
      when JSON_String_Type =>
         Put_Line (Name & ":" & Get(Value));
      when JSON_Array_Type =>
         Put(Name);
         Print_JSON_Array(Get(Value));
      when JSON_Object_Type =>
         Put_Line (Name & "{");
         Map_JSON_Object (Val => Value,CB  => Handler'Access);
         Put_Line ("}");
      end case;
	--  Decide output depending on the kind of JSON field we're dealing with.
	--  Note that if we get a JSON_Object_Type, then we recursively call
	--  Map_JSON_Object again, which in turn calls this Handler procedure.
   end Handler;

   procedure Print_JSON_Array(json_arr: in JSON_Array) is
      A_JSON_Value : JSON_Value;
      Array_Length : constant Natural := Length (json_arr);
      bool_element : Boolean;
      int_element : Integer;
      float_element : Float;
      arr_element : JSON_Array;
   begin
      Put("[");
      New_Line;
      for J in 1 .. Array_Length loop
         A_JSON_Value := Get (Arr => json_arr,Index => J);
         case Kind (Val => A_JSON_Value) is
         when JSON_Null_Type =>
            Put_Line("null");
         when JSON_Boolean_Type =>
            bool_element := Get(A_JSON_Value);
            Put_Line(Boolean'Image(bool_element));
         when JSON_Int_Type =>
            int_element := Get(A_JSON_Value);
            Put_Line(Integer'Image(int_element));
         when JSON_Float_Type =>
            float_element := Get(A_JSON_Value);
            Put_Line(Float'Image(float_element));
         when JSON_String_Type =>
            Put_Line(Get(A_JSON_Value));
         when JSON_Array_Type =>
            arr_element := Get(A_JSON_Value);
            Print_JSON_Array(arr_element);
         when JSON_Object_Type =>
            Put_Line("{");
            Map_JSON_Object (Val => A_JSON_Value,CB  => Handler'Access);
            Put_Line("}");
         end case;
         if J < Array_Length then
            Put_Line(",");
         else
            Put_Line("]");
         end if;
      end loop;
   end Print_JSON_Array;

   procedure Print_Json(Text : String) is
   begin
      Map_JSON_Object(Val => Get_Json_Value(Text), CB => Handler'Access);
   end Print_Json;

   procedure Print_Json_Value(J : Json_Value) is
   begin
      Map_JSON_Object(Val => J, CB => Handler'Access);
   end Print_Json_value;

end Json_Helper;
