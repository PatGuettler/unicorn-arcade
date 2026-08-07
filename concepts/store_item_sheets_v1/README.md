# Store Item Modeling Sheets v1

These 18 sheets are primary-angle concept inputs for generating improved 3D decor models for all 107 catalog items. Sheet 01 uses the original 3-column by 2-row layout. Sheets 02–17 use 2 columns by 3 rows. Sheet 18 intentionally leaves the bottom-right cell empty.

## Art direction

- Pure white background with isolated, disconnected props and generous whitespace.
- Slightly elevated front-left three-quarter primary view.
- Polished stylized mobile-game forms in pink, lilac, aqua, cream, and restrained warm gold.
- No labels, borders, rooms, shared platforms, or overlapping objects.

## Reconstruction and separation workflow

1. Generate one 3D scene from the complete sheet.
2. Separate the result by spatial grid region, not only by loose geometry. This keeps an item's disconnected functional pieces—such as chair wheels, cords, handles, or bows—grouped together.
3. Preserve each region's UVs and materials while extracting it to an individual scene.
4. Remove generated ground planes and reconstruction debris.
5. Recenter each item at its floor-contact origin, normalize its in-game scale, repair hidden/back surfaces where needed, optimize textures and geometry, and validate it in Godot.

The sheets define the primary visible design. Hidden surfaces inferred by a reconstruction service still require visual review.

## Cell map

Position order for sheets 02–17 is `TL, TR, ML, MR, BL, BR`. Sheet 01 uses `TL, TC, TR, BL, BC, BR`.

| Sheet | File | Cell mapping |
| --- | --- | --- |
| 01 | `store_items_sheet_01.png` | TL `lamp` Lava Lamp; TC `rug` Fluffy Rug; TR `plant` Magic Plant; BL `chair` Gaming Chair; BC `arcade` Mini Arcade; BR `trophy` Gold Trophy |
| 02 | `store_items_sheet_02.png` | TL `bed_single` Single Bed; TR `bed_king` King Size Bed; ML `bed_race` Race Car Bed; MR `bed_cloud` Cloud Bed; BL `bed_bunk` Bunk Bed; BR `bed_coffin` Vampire Bed |
| 03 | `store_items_sheet_03.png` | TL `table_coffee` Coffee Table; TR `table_dining` Dining Table; ML `desk_office` Office Desk; MR `table_night` Nightstand; BL `table_pool` Pool Table; BR `lamp_floor` Floor Lamp |
| 04 | `store_items_sheet_04.png` | TL `lamp_desk` Desk Lamp; TR `chandelier` Chandelier; ML `candle` Candle; MR `lantern` Paper Lantern; BL `disco` Disco Ball; BR `flashlight` Flashlight |
| 05 | `store_items_sheet_05.png` | TL `rug_welcome` Welcome Mat; TR `rug_persian` Persian Rug; ML `rug_bear` Faux Bear Rug; MR `rug_magic` Magic Carpet; BL `rug_puzzle` Puzzle Mat; BR `pet_cat_blk` Black Cat |
| 06 | `store_items_sheet_06.png` | TL `pet_cat_org` Tabby Cat; TR `pet_dog_dog` Good Boy; ML `pet_dog_pud` Poodle; MR `pet_dog_ser` Service Dog; BL `pet_paw` Paw Prints; BR `pet_fish` Goldfish |
| 07 | `store_items_sheet_07.png` | TL `pet_hamster` Hamster; TR `pet_mouse` Mouse; ML `pet_chick` Baby Chick; MR `pet_frog` Tree Frog; BL `pet_turtle` Turtle; BR `pet_dragon` Tiny Dragon |
| 08 | `store_items_sheet_08.png` | TL `toy_bear` Teddy Bear; TR `toy_robot` Robot; ML `toy_doll` Doll; MR `toy_kite` Kite; BL `toy_yoyo` Yo-Yo; BR `toy_train` Train Set |
| 09 | `store_items_sheet_09.png` | TL `toy_blocks` Building Blocks; TR `toy_ball` Soccer Ball; ML `tv_retro` Retro TV; MR `tv_flat` Wall TV; BL `pc_gamer` Gamer PC; BR `console` Game Console |
| 10 | `store_items_sheet_10.png` | TL `radio` Radio; TR `phone_retro` Rotary Phone; ML `camera` Camera; MR `xmas_tree` Xmas Tree; BL `xmas_santa` Santa Claus; BR `xmas_sock` Stocking |
| 11 | `store_items_sheet_11.png` | TL `xmas_gift` Gift Box; TR `xmas_bell` Jingle Bell; ML `xmas_deer` Reindeer; MR `xmas_snow` Snowman; BL `xmas_flake` Snowflake; BR `hall_pump` Pumpkin |
| 12 | `store_items_sheet_12.png` | TL `hall_ghost` Ghost; TR `hall_skull` Skull; ML `hall_web` Spider Web; MR `hall_spider` Giant Spider; BL `hall_bat` Bat; BR `hall_alien` Alien |
| 13 | `store_items_sheet_13.png` | TL `hall_mask` Goblin Mask; TR `mush_stool` Mushroom Log Stool; ML `mom_tea` Mom's Tea Set; MR `fruit_basket` Fruit Basket; BL `bamboo_speaker` Bamboo Speaker; BR `butterfly_model` Butterfly Model |
| 14 | `store_items_sheet_14.png` | TL `star_lamp` Star Fragment Lamp; TR `moon_chair` Crescent Moon Chair; ML `moss_ball` Glowing Moss Ball; MR `espresso_maker` Stovetop Espresso; BL `ironwood_counter` Ironwood Counter; BR `fairy_lights` Fairy Light Strand |
| 15 | `store_items_sheet_15.png` | TL `skylight_poster` Skylight Poster; TR `peach_wall` Peach Wallpaper; ML `crown_display` Royal Crown Display; MR `golden_toilet` Golden Toilet; BL `studio_spot` Studio Spotlight; BR `book_stack` Cozy Book Stack |
| 16 | `store_items_sheet_16.png` | TL `record_player` Vintage Record Player; TR `bubble_machine` Bubble Machine; ML `zen_garden` Mini Zen Garden; MR `terrarium` Fairy Terrarium; BL `uni_fountain` Unicorn Fountain; BR `crystal_ball` Fortune Crystal Ball |
| 17 | `store_items_sheet_17.png` | TL `hammock` Leaf Hammock; TR `brick_oven` Brick Oven; ML `ac_fish_tank` Aquarium Tank; MR `ac_anthurium` Anthurium Plant; BL `ac_typewriter` Typewriter; BR `ac_cello` Cello |
| 18 | `store_items_sheet_18.png` | TL `ac_menu_board` Menu Chalkboard; TR `uni_rainbow_shelf` Rainbow Shelf; ML `uni_glitter_rug` Glitter Rug; MR `uni_cloud_lamp` Cloud Pendant Lamp; BL `uni_horn_planter` Horn Planter; BR intentionally empty |

## Integrated batch 01

The approved reconstruction from Sheet 01 is stored as `godot/assets/models/store/store1_mobile.glb`. Its named meshes are `lamp`, `rug`, `plant`, `chair`, `arcade`, and `trophy`. Blender source, separation/optimization reports, and the approved review contact sheet are preserved under `art_sources/store_items/store1` and `previews/store_items/store1`.
