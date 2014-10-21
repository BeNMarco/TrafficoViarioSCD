with Gnatcoll.JSON;use Gnatcoll.JSON;
--  with Ada.Containers.Ordered_Maps;
with Ada.Strings.Unbounded;

package JSON_Helper is
   package SU renames Ada.Strings.Unbounded;

   function Load_File(File_Name : String) return String;
	-- #
	-- # Creates a JSON_Value from a Json input. Json data can be retrieved either from file or
	-- # from a given string, it depends on what the caller specify.
	 -- #
   function Get_Json_Value(Json_String : String := ""; Json_File_Name : String := "") return JSON_Value;

   procedure Handler (Name : in UTF8_String;Value : in JSON_Value);

   procedure Print_JSON_Array(json_arr : in JSON_Array);

   procedure Print_Json(Text : String);

   procedure Print_Json_Value(J : Json_Value);

end Json_Helper;
