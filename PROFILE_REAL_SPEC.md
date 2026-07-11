# PROFILE REAL SPEC — Honest Profile, Honest Feed (v0.29.0)

Execution contract. Sonnet default. All decisions final.
The entire Profile page is hardcoded fake HTML: stat numbers
(7 / 3 / 12) and four My Plants rows (Fig tree, American
Beautyberry, Blackberry, Texas Redbud) are static markup that
has never touched the database. Plus: new plants land at the
BOTTOM of the feed, and there is no pull-to-refresh.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. HONEST-STATES VIOLATION, the worst remaining: the Profile
   shows invented numbers and invented plants to every user.
   All four hardcoded My Plants rows and all three hardcoded
   stat numbers are DELETED and replaced with real queries.
2. My Plants = the signed-in user's own plants, newest first,
   from the plants table (user_id = session user). Each row:
   type dot (color by tags, matching existing .plant-log-dot
   classes), plant name, and the planted_at date formatted
   like the existing rows (e.g. "Apr 12"). Discovered plants
   show the same row with a small "Found" marker consistent
   with feed chips.
3. Stats: keep the three-stat layout but make each real, or
   remove any stat that cannot be honestly computed:
   - "Planted": COUNT of the user's plants where kind='planted'
   - "Found": COUNT where kind='discovered' (rename the second
     stat to this — it is honest and computable)
   - Third stat: "Inspires" = COUNT of inspires received on the
     user's plants. If that query is awkward, DELETE the third
     stat entirely rather than invent a number.
4. Empty states (honest, no fake data): no session or zero
   plants -> My Plants shows "Nothing planted yet. Your first
   plant lands here." Stats show 0, never placeholder numbers.
5. Feed ordering: newest FIRST. Verify loadFeed orders by
   planted_at descending; a newly logged plant must appear as
   the TOP card immediately.
6. Pull-to-refresh on the FEED view: a standard touch
   pull-down gesture at scroll-top that re-runs loadFeed() AND
   loadDbPins() (they share a data source), with a brief
   spinner/indicator. Also add a small refresh control in the
   feed header for desktop (no touch gesture there).
7. Profile name persistence: after OAuth return, once
   loadOwnProfile() resolves, explicitly re-render the profile
   hero and My Plants so the real display_name and real plants
   show — never leave a signed-in user showing 'Planter' when
   the profiles row holds a real name. Only open the setup
   sheet if the profile LOADED and display_name is genuinely
   still 'Planter' (guard the race).

## Claude Code tasks (one commit, v0.29.0)

### Task 1 — Delete the fake profile markup
Remove the four hardcoded .plant-log-item rows and the three
hardcoded .stat-num values from #profile-view.

### Task 2 — Real My Plants
Add renderMyPlants(): query the session user's plants
(select id, plant_name, tags, kind, planted_at; eq user_id;
order planted_at desc; limit 50), render rows per decision 2,
with the decision-4 empty state. Call it on profile load, after
a successful plant log, and after OAuth return.

### Task 3 — Real stats
Implement decision 3 with real counts. Prefer head:true count
queries. Any stat that cannot be computed honestly is removed,
not faked.

### Task 4 — Feed newest-first + pull-to-refresh
Confirm/fix loadFeed ordering to planted_at descending so new
plants appear at the TOP. Implement decision 6 (touch
pull-to-refresh at scroll-top on #feed-view + a desktop refresh
control), calling loadFeed() and loadDbPins().

### Task 5 — Name persistence on OAuth return
Implement decision 7 in handleOauthReturn().

### Task 6 — Version, docs, self-verify
Fan-out: footer v0.29.0 + sw.js CACHE appleseed-v0-29-0.
CLAUDE_CONTEXT.md: fake-profile removal (honest-states),
renderMyPlants landmark, feed sort + refresh, OAuth re-render,
roadmap (haze-dot fix pending as its own build).
Post-deploy self-verify (rule 11, four probes):
1. index.html: v0.29.0 + zero occurrences of the hardcoded
   strings "Texas Redbud" and "Apr 12" inside #profile-view +
   renderMyPlants present + feed order descending + pull-to-
   refresh handler present
2. sw.js cache = appleseed-v0-29-0
3. GET {SUPABASE_URL}/rest/v1/plants?select=kind&limit=1 with
   apikey + Bearer -> 200
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer -> 200, all <= 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Profile: My Plants shows YOUR real plants (okra included),
  newest first; stats show real counts, not 7/3/12
- Log a new plant: it appears at the TOP of the feed
- Pull down on the feed: it refreshes
- Clear data + Google sign-in: your real name shows, real
  plants show, no setup-sheet re-prompt
- Map circles unchanged (dot fix is the next build)
