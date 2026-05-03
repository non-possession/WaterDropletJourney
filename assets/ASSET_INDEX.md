# Asset Index

## Originals

- `assets/originals/b1.png`: 原始瓦片/装饰图集参考
- `assets/originals/b2.png`: 原始场景大图
- `assets/originals/p1.png`: 原始水滴状态图
- `assets/originals/p2.png`: 原始水滴待机帧图

## Exported Tiles

- `assets/tiles/b2/`: 从 `b2.png` 切出的地图瓦片，共 48 张，命名格式为 `b2_tile_rXX_cXX.png`
- 当前按 `8 x 6` 网格切分，每张瓦片尺寸为 `181 x 181`

## Thematic Atlases From `b2`

- `assets/atlases/river/`: 河道专题切片，适合拼接水道、河岸和弯道变化
- `assets/atlases/grass/`: 草地专题切片，适合铺设开阔草地区域
- `assets/atlases/bridge/`: 桥专题切片，包含桥本体和带两岸的桥段
- `assets/atlases/trees/`: 树木专题切片，包含几棵主要树形的独立图块
- `assets/atlases/river_atlas.png`: 河道总图集
- `assets/atlases/grass_atlas.png`: 草地图集
- `assets/atlases/bridge_atlas.png`: 桥图集
- `assets/atlases/trees_atlas.png`: 树木图集
- 详细清单见 `assets/atlases/ATLAS_INDEX.md`

## Water State Sprites

- `assets/sprites/water_states/water_calm.png`: 平静，圆润、透明、轻微波动
- `assets/sprites/water_states/water_tense.png`: 紧张，被拉长、边缘更颤
- `assets/sprites/water_states/water_cold.png`: 寒冷，边缘结晶化、更锋利
- `assets/sprites/water_states/water_sad.png`: 悲伤，更沉、更低垂、反光更弱
- `assets/sprites/water_states/water_joy.png`: 喜悦，更轻、更亮、边缘更活泼
- `assets/sprites/water_states/water_evaporating.png`: 蒸腾，轮廓变散、局部飘离
- `assets/sprites/water_states/water_absorbed.png`: 被吸收，形体被拉入方向性流动中，核心仍保留
- `assets/sprites/water_states/water_resting.png`: 额外补充状态，闭眼静息版

## Current Water Player Sprites

- `assets/sprites/water_player_spirit/`: 当前主角水滴的基础逐帧表现与状态叠层资源
- `assets/sprites/water_player_layers/`: 当前主角水滴的分层表现资源，包括主体、外轮廓、内亮核、高光、拖尾和姿态层
- `assets/sprites/water_siblings/`: 第一章开场中用于群体水灵氛围的兄弟姐妹水滴资源

## Bush Interaction Sprites

- `assets/originals/toyv1_bush_layers_sheet.png`: toyv1 灌木互动分层原始素材板
- `assets/sprites/bush_interaction/back_leaves.png`: 灌木后景叶层，负责体积和深色背景
- `assets/sprites/bush_interaction/front_leaves.png`: 灌木前景叶层，负责主要可见轮廓
- `assets/sprites/bush_interaction/contact_leaves.png`: 与水滴接触时覆盖在前方的稀疏叶片
- `assets/sprites/bush_interaction/local_glow_mask.png`: 停驻回应时使用的局部柔光遮罩

## Suggested Usage

- 地图拼接或参考切片：使用 `assets/tiles/b2/`
- 水滴情绪状态切换：使用 `assets/sprites/water_states/`
- 主角水滴当前可玩表现：优先使用 `assets/sprites/water_player_spirit/` 与 `assets/sprites/water_player_layers/`
- 水滴与灌木互动：使用 `assets/sprites/bush_interaction/` 的分层素材，避免直接把整张 AI 插画放进场景
- sprite 透明背景和画布安全检查：运行 `python3 scripts/tools/audit_sprite_layers.py`
