import { assertEquals } from "https://deno.land/std@0.206.0/assert/assert_equals.ts";
import { assertObjectMatch } from "https://deno.land/std@0.206.0/assert/assert_object_match.ts";
import { Group, List } from "./plugins.ts";

Deno.test("Group", () => {
  const group = Group(
    { lazy: false, rtp: "" },
    [
      {
        repo: "Shougo/dpp.vim",
      },
      {
        repo: "Shougo/dpp-ext-lazy",
        depends: ["dpp.vim"],
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
      depends: ["dpp.vim"],
      lazy: false,
      rtp: "",
    },
  );
});

Deno.test("List", () => {
  const list = List([
    {
      repo: "Shougo/dpp.vim",
    },
    {
      repo: "Shougo/dpp-ext-lazy",
      depends: ["dpp.vim"],
    },
  ]);
  assertEquals(list.length, 2);
  assertObjectMatch(
    list[0],
    {
      repo: "Shougo/dpp.vim",
      name: "dpp.vim",
    },
  );
  assertObjectMatch(
    list[1],
    {
      repo: "Shougo/dpp-ext-lazy",
      depends: ["dpp.vim"],
      name: "dpp-ext-lazy",
    },
  );
});
