import { assertEquals } from "https://deno.land/std@0.206.0/assert/assert_equals.ts";
import { assertObjectMatch } from "https://deno.land/std@0.206.0/assert/assert_object_match.ts";
import { Group } from "./plugins.ts";

Deno.test("Group", () => {
  const group = Group(
    { lazy: false, rtp: "" },
    [
      {
        repo: "Shougo/dpp.vim",
      },
      {
        repo: "Shougo/dpp-ext-lazy",
        depends: ["dpp"],
      },
    ],
  );
  assertEquals(group.length, 2);
  assertObjectMatch(
    group[0],
    {
      repo: "Shougo/dpp.vim",
      lazy: false,
      rtp: "",
    },
  );
  assertObjectMatch(
    group[1],
    {
      repo: "Shougo/dpp-ext-lazy",
      depends: ["dpp"],
      lazy: false,
      rtp: "",
    },
  );
});
