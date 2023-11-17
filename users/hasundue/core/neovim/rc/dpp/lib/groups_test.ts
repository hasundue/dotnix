import { assertEquals, assertObjectMatch } from "./std/assert.ts";
import { ClosedGroup, Group, Init } from "./groups.ts";

const assert = (actual: Init[], expected: Init[]) => {
  assertEquals(actual.length, 2);
  assertObjectMatch(actual[0], expected[0]);
  assertObjectMatch(actual[1], expected[1]);
};

const expectedGroup = [
  {
    repo: "Shougo/dpp.vim",
    lazy: false,
    rtp: "",
  },
  {
    repo: "Shougo/dpp-ext-lazy",
    depends: ["dpp"],
    lazy: false,
    rtp: "",
  },
] satisfies Init[];

Deno.test("Group", () => {
  assert(
    Group({ lazy: false, rtp: "" }, [
      {
        repo: "Shougo/dpp",
      },
      {
        repo: "Shougo/dpp-ext-lazy",
        depends: ["dpp"],
      },
    ]),
    expectedGroup,
  );
});

Deno.test("Group - nested", () => {
  assert(
    Group({ lazy: false, rtp: "" }, [
      {
        repo: "Shougo/dpp.vim",
      },
      ...Group({ depends: ["dpp"] }, [
        {
          repo: "Shougo/dpp-ext-lazy",
        },
      ]),
    ]),
    expectedGroup,
  );
});

const expectedClosedGroup = [
  {
    name: "dpp",
    repo: "Shougo/dpp.vim",
  },
  {
    name: "dpp-ext-lazy",
    repo: "Shougo/dpp-ext-lazy",
    depends: ["dpp"],
  },
] satisfies ClosedGroup<"Shougo/dpp.vim" | "Shougo/dpp-ext-lazy">;

Deno.test("ClosedGroup", () => {
  assert(
    ClosedGroup(
      {
        repo: "Shougo/dpp.vim",
      },
      {
        repo: "Shougo/dpp-ext-lazy",
        depends: ["dpp"],
      },
    ),
    expectedClosedGroup,
  );
});

Deno.test("ClosedGroup - with nested Groups", () => {
  assert(
    ClosedGroup(
      {
        repo: "Shougo/dpp.vim",
      },
      ...Group({ depends: ["dpp"] }, [
        { repo: "Shougo/dpp-ext-lazy" },
      ]),
    ),
    expectedClosedGroup,
  );
});

Deno.test("ClosedGroup - with top-level Group", () => {
  assert(
    ClosedGroup(...Group({ lazy: false, rtp: "" }, [
      {
        repo: "Shougo/dpp.vim",
      },
      {
        repo: "Shougo/dpp-ext-lazy",
        depends: ["dpp"],
      },
    ])),
    expectedClosedGroup,
  );
});
