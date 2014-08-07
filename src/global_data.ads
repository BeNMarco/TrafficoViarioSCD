


package global_data is
   pragma Shared_Passive;

   function get_num_quartieri return Positive;

private

   num_quartieri: constant Positive:=1;

end global_data;
