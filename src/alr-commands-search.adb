with Ada.Strings.Fixed;

with Alire.Containers;
with Alire.Index;
with Alire.Releases;

with Alr.Checkout;
with Alr.Utils;

with Semantic_Versioning;

with Table_IO;

package body Alr.Commands.Search is

   -------------
   -- Execute --
   -------------

   overriding procedure Execute (Cmd : in out Command) is
      use Ada.Strings.Fixed;

      Found   : Natural := 0;

      Tab : Table_IO.Table;

      ------------------
      -- List_Release --
      ------------------

      procedure List_Release (R : Alire.Releases.Release) is
      begin
         if Cmd.Prop.all = "" or else R.Property_Contains (Cmd.Prop.all) then
            Found := Found + 1;
            Tab.New_Row;
            Tab.Append (R.Project);
            Tab.Append (Semantic_Versioning.Image (R.Version) &
                        (if R.Origin.Is_Native then " (native)" else "") &
                        (if Checkout.Available_Currently (R) then "" else " (unavail)"));
            Tab.Append (R.Description);
         end if;
      end List_Release;

      use Alire.Containers.Release_Sets;
   begin
      Requires_No_Bootstrap;

      if Num_Arguments = 0 and then not Cmd.List and then Cmd.Prop.all = "" then
         -- no search term, nor --list, nor --prop
         Trace.Error ("Please provide a search term, --property, or use --list to show all available releases");
         raise Wrong_Command_Arguments;
      end if;

      if Num_Arguments = 0 and then Cmd.Prop.all /= "" then
         Cmd.List := True;
      end if;

      if Cmd.List and then Num_Arguments /= 0 then
         Trace.Error ("Listing is incompatible with searching");
         raise Wrong_Command_Arguments;
      end if;

      --  End of option verification, start of search

      if Cmd.List then
         for I in Alire.Index.Releases.Iterate loop
            if Cmd.Full or else I = Alire.Index.Releases.Last or else
              Alire.Index.Releases (I).Project /= Alire.Index.Releases (Next (I)).Project
            then
               List_Release (Alire.Index.Releases (I));
            end if;
         end loop;
      else
         declare
            Pattern : constant String := Argument (1);
         begin
            if not Cmd.List then
               Log ("Searching " & Utils.Quote (Pattern) & "...", Detail);
            end if;

            for I in Alire.Index.Releases.Iterate loop
               if Count (Alire.Index.Releases (I).Project, Pattern) > 0 then
                  if Cmd.Full or else I = Alire.Index.Releases.Last or else
                    Alire.Index.Releases (I).Project /= Alire.Index.Releases (Next (I)).Project
                  then
                     List_Release (Alire.Index.Releases (I));
                  end if;
               end if;
            end loop;
         end;
      end if;

      if Found = 0 then
         Log ("No hits");
      else
         Tab.Print (Separator => "  ");
      end if;
   end Execute;

   overriding procedure Setup_Switches
     (Cmd    : in out Command;
      Config : in out GNAT.Command_Line.Command_Line_Configuration)
   is
      use GNAT.Command_Line;
   begin
      Define_Switch (Config,
                     Cmd.Full'Access,
                     "", "--full",
                     "Show all versions of a project (newest only otherwise)");

      Define_Switch (Config,
                     Cmd.List'Access,
                     "", "--list",
                     "List all available releases");

      Define_Switch (Config,
                     Cmd.Prop'Access,
                     "", "--property=",
                     "Search TEXT in property values",
                     Argument => "TEXT");
   end Setup_Switches;

end Alr.Commands.Search;
