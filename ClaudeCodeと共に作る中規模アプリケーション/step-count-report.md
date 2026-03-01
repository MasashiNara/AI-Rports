# ソースコード ステップカウントレポート

計測日: 2026-03-01
計測ツール: cloc v1.98
対象: Git管理下の全ソースファイル（生成ファイル・ドキュメント・設定除外）

各列の意味：**総** = 総ステップ数、**有効** = 有効ステップ数（空行・コメント除外）、**空** = 空行、**※** = コメント行

---

## 全体サマリー

| カテゴリ | ファイル数 | 総ステップ数 | 有効ステップ数 | 空行 | コメント |
|----------|--------:|----------:|-----------:|-----:|-------:|
| **Backend 本体** (app/) | 92 | 14,843 | **10,281** | 2,578 | 1,984 |
| **Backend テスト** (tests/) | 72 | 23,772 | **17,212** | 4,109 | 2,451 |
| **Frontend 本体** (src/) | 101 | 11,483 | **9,865** | 966 | 652 |
| **Frontend テスト** (test/e2e) | 54 | 5,982 | **4,611** | 918 | 453 |
| **生成ファイル** (schema等) | 3 | 17,228 | 16,521 | 1 | 706 |
| **ドキュメント** (docs/) | 26 | 15,431 | 12,449 | 2,917 | 65 |
| **設定/インフラ** | 45 | 3,874 | 3,043 | 733 | 98 |
| **合計** | **393** | **92,613** | **73,982** | 12,222 | 6,409 |

### 手書きソースコード（生成・ドキュメント・設定除外）

| 区分 | 総ステップ数 | 有効ステップ数 |
|------|----------:|-----------:|
| **本体コード** (Backend + Frontend) | 26,326 | **20,146** |
| **テストコード** (Backend + Frontend) | 29,754 | **21,823** |
| **本体 + テスト 合計** | **56,080** | **41,969** |

テスト/本体比率: **1.08**（本体コードより多いテストコードを持つ）

---

## ディレクトリ別集計

### Backend 本体 (app/) 内訳

| ディレクトリ | ファイル数 | 総ステップ数 | 有効ステップ数 | 空行 | コメント |
|-------------|--------:|----------:|-----------:|-----:|-------:|
| services/ | 30 | 7,446 | **4,919** | 1,212 | 1,315 |
| api/ui/ | 10 | 1,494 | **1,165** | 212 | 117 |
| api/ui/admin/ | 11 | 1,497 | **1,216** | 205 | 76 |
| api/v1/ | 7 | 828 | **694** | 99 | 35 |
| api/mcp/ | 3 | 436 | **305** | 71 | 60 |
| schemas/ | 10 | 976 | **494** | 327 | 155 |
| models/ | 12 | 575 | **416** | 113 | 46 |
| core/ | 7 | 466 | **284** | 120 | 62 |
| tasks/ | 3 | 265 | **176** | 50 | 39 |
| root (main/worker) | 2 | 434 | **342** | 65 | 27 |
| **合計** | **92** | **14,843** | **10,281** | **2,578** | **1,984** |

### Frontend 本体 (src/) 内訳

| ディレクトリ | ファイル数 | 総ステップ数 | 有効ステップ数 | 空行 | コメント |
|-------------|--------:|----------:|-----------:|-----:|-------:|
| features/admin/ | 13 | 3,338 | **3,047** | 230 | 61 |
| hooks/ | 12 | 1,735 | **1,424** | 164 | 147 |
| routes/ | 14 | 1,242 | **1,146** | 88 | 8 |
| lib/ | 10 | 1,143 | **716** | 153 | 274 |
| features/articles/ | 9 | 1,037 | **895** | 76 | 66 |
| components/ui/ (shadcn) | 16 | 965 | **876** | 89 | 0 |
| features/ai/ | 4 | 723 | **652** | 59 | 12 |
| components/editor/ | 4 | 317 | **256** | 26 | 35 |
| components/layout/ | 3 | 199 | **182** | 16 | 1 |
| api/ | 5 | 167 | **127** | 16 | 24 |
| features/auth/ | 3 | 118 | **103** | 13 | 2 |
| components/wiki/ | 1 | 114 | **102** | 7 | 5 |
| stores/ | 2 | 115 | **100** | 11 | 4 |
| features/search/ | 1 | 99 | **87** | 5 | 7 |
| root (App/main/css/types) | 4 | 171 | **152** | 13 | 6 |
| **合計** | **101** | **11,483** | **9,865** | **966** | **652** |

---

## ソースファイル単位 ステップカウント

### Backend 本体 (app/)

#### services/ (30 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| article_service.py | 726 | 485 | 112 | 129 |
| git_service.py | 636 | 397 | 133 | 106 |
| pdf_service.py | 711 | 345 | 90 | 276 |
| ldap_service.py | 353 | 272 | 52 | 29 |
| audit_service.py | 308 | 240 | 40 | 28 |
| oembed_service.py | 342 | 230 | 56 | 56 |
| opensearch_service.py | 270 | 227 | 24 | 19 |
| auth_service.py | 309 | 227 | 47 | 35 |
| markdown_renderer.py | 364 | 223 | 70 | 71 |
| permission_service.py | 274 | 194 | 39 | 41 |
| llm_service.py | 226 | 179 | 24 | 23 |
| attachment_service.py | 298 | 174 | 50 | 74 |
| wiki_service.py | 252 | 168 | 45 | 39 |
| search_engine.py | 238 | 158 | 44 | 36 |
| user_service.py | 226 | 154 | 36 | 36 |
| rag_service.py | 194 | 151 | 31 | 12 |
| llm_config_service.py | 187 | 141 | 30 | 16 |
| export_service.py | 204 | 126 | 33 | 45 |
| indexing_service.py | 190 | 120 | 38 | 32 |
| api_key_service.py | 168 | 116 | 30 | 22 |
| search_service.py | 146 | 105 | 22 | 19 |
| tag_suggestion_service.py | 135 | 95 | 24 | 16 |
| article_generation_service.py | 134 | 93 | 24 | 17 |
| embedding_service.py | 125 | 88 | 15 | 22 |
| rate_limiter.py | 107 | 66 | 25 | 16 |
| summarization_service.py | 90 | 65 | 15 | 10 |
| meta_yaml_service.py | 58 | 34 | 13 | 11 |
| search_types.py | 43 | 26 | 11 | 6 |
| prompts.py | 132 | 20 | 39 | 73 |
| **小計** | **7,446** | **4,919** | **1,212** | **1,315** |

#### api/ui/ (10 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| articles.py | 407 | 335 | 47 | 25 |
| ai.py | 338 | 238 | 55 | 45 |
| attachments.py | 162 | 129 | 22 | 11 |
| auth.py | 149 | 114 | 23 | 12 |
| versions.py | 113 | 95 | 13 | 5 |
| wikis.py | 95 | 74 | 15 | 6 |
| tags.py | 87 | 71 | 12 | 4 |
| oembed.py | 81 | 60 | 15 | 6 |
| search.py | 62 | 49 | 10 | 3 |
| **小計** | **1,494** | **1,165** | **212** | **117** |

#### api/ui/admin/ (11 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| ldap.py | 319 | 263 | 37 | 19 |
| articles.py | 234 | 199 | 26 | 9 |
| ai.py | 176 | 143 | 25 | 8 |
| api_keys.py | 138 | 114 | 20 | 4 |
| users.py | 135 | 111 | 17 | 7 |
| settings.py | 138 | 108 | 22 | 8 |
| attachments.py | 117 | 94 | 17 | 6 |
| audit.py | 96 | 78 | 15 | 3 |
| search.py | 87 | 65 | 15 | 7 |
| export.py | 57 | 41 | 11 | 5 |
| **小計** | **1,497** | **1,216** | **205** | **76** |

#### api/v1/ (7 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| articles.py | 344 | 290 | 38 | 16 |
| admin.py | 141 | 120 | 17 | 4 |
| tags.py | 106 | 91 | 12 | 3 |
| attachments.py | 98 | 79 | 13 | 6 |
| search.py | 70 | 58 | 10 | 2 |
| wikis.py | 68 | 56 | 9 | 3 |
| **小計** | **828** | **694** | **99** | **35** |

#### api/mcp/ (3 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| tools.py | 287 | 205 | 41 | 41 |
| server.py | 148 | 100 | 30 | 18 |
| **小計** | **436** | **305** | **71** | **60** |

#### schemas/ (10 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| article.py | 431 | 202 | 149 | 80 |
| ldap.py | 123 | 83 | 30 | 10 |
| ai.py | 140 | 50 | 58 | 32 |
| meta.py | 72 | 41 | 21 | 10 |
| llm_config.py | 51 | 31 | 15 | 5 |
| api_key.py | 49 | 28 | 16 | 5 |
| auth.py | 43 | 23 | 15 | 5 |
| audit.py | 33 | 21 | 9 | 3 |
| oembed.py | 34 | 15 | 14 | 5 |
| **小計** | **976** | **494** | **327** | **155** |

#### models/ (12 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| user.py | 73 | 60 | 10 | 3 |
| api_key.py | 65 | 52 | 10 | 3 |
| role.py | 70 | 50 | 15 | 5 |
| group.py | 70 | 50 | 15 | 5 |
| session.py | 48 | 35 | 10 | 3 |
| acl.py | 44 | 32 | 8 | 4 |
| ldap_group_mapping.py | 44 | 31 | 10 | 3 |
| attachment.py | 40 | 26 | 8 | 6 |
| __init__.py | 27 | 24 | 2 | 1 |
| article_source_ref.py | 36 | 21 | 9 | 6 |
| system_setting.py | 31 | 19 | 8 | 4 |
| base.py | 27 | 16 | 8 | 3 |
| **小計** | **575** | **416** | **113** | **46** |

#### core/ (7 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| exceptions.py | 165 | 101 | 47 | 17 |
| config.py | 109 | 66 | 24 | 19 |
| constants.py | 60 | 48 | 5 | 7 |
| enums.py | 59 | 29 | 21 | 9 |
| database.py | 30 | 22 | 8 | 0 |
| security.py | 43 | 18 | 15 | 10 |
| **小計** | **466** | **284** | **120** | **62** |

#### tasks/ (3 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| indexing.py | 129 | 90 | 21 | 18 |
| llm_tasks.py | 135 | 86 | 29 | 20 |
| **小計** | **265** | **176** | **50** | **39** |

#### root (2 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| main.py | 402 | 317 | 61 | 24 |
| worker.py | 32 | 25 | 4 | 3 |
| **小計** | **434** | **342** | **65** | **27** |

#### **Backend 本体 合計: 総 14,843 / 有効 10,281**

---

### Backend テスト (tests/)

#### unit/ (53 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| test_ldap.py | 1,151 | 874 | 196 | 81 |
| test_permission_service.py | 1,055 | 792 | 179 | 84 |
| test_git_service.py | 663 | 524 | 79 | 60 |
| test_admin_ai_api.py | 619 | 466 | 98 | 55 |
| test_mcp_server.py | 626 | 463 | 129 | 34 |
| test_article_service.py | 551 | 444 | 67 | 40 |
| test_oembed_service.py | 522 | 415 | 90 | 17 |
| test_ai_api.py | 563 | 413 | 96 | 54 |
| test_pdf_service.py | 499 | 369 | 97 | 33 |
| test_articles_api.py | 461 | 346 | 66 | 49 |
| test_audit_service.py | 502 | 320 | 133 | 49 |
| test_models.py | 442 | 304 | 102 | 36 |
| test_llm_service.py | 420 | 292 | 76 | 52 |
| test_source_ref.py | 377 | 288 | 50 | 39 |
| test_api_key_service.py | 402 | 288 | 82 | 32 |
| test_export_service.py | 365 | 277 | 58 | 30 |
| test_llm_config_service.py | 414 | 271 | 86 | 57 |
| test_attachments_api.py | 349 | 264 | 51 | 34 |
| test_attachment_service.py | 361 | 259 | 65 | 37 |
| test_admin_api.py | 331 | 248 | 40 | 43 |
| test_rag_service.py | 345 | 238 | 66 | 41 |
| test_tag_suggestion_service.py | 323 | 226 | 59 | 38 |
| test_oembed_api.py | 278 | 220 | 38 | 20 |
| test_resolve_api.py | 266 | 218 | 32 | 16 |
| test_search_engine.py | 293 | 210 | 51 | 32 |
| test_indexing_service.py | 261 | 189 | 49 | 23 |
| test_export_api.py | 226 | 176 | 28 | 22 |
| test_admin_audit_api.py | 231 | 170 | 47 | 14 |
| test_article_generation_service.py | 249 | 168 | 46 | 35 |
| test_auth_api.py | 242 | 164 | 51 | 27 |
| test_opensearch_service.py | 232 | 162 | 39 | 31 |
| test_tags_search_wiki_api.py | 207 | 155 | 27 | 25 |
| test_deps_api.py | 242 | 140 | 79 | 23 |
| test_markdown_renderer.py | 224 | 139 | 45 | 40 |
| test_search_service.py | 174 | 136 | 24 | 14 |
| test_admin_api_keys.py | 189 | 131 | 42 | 16 |
| test_wiki_service.py | 171 | 127 | 25 | 19 |
| test_ai_schemas.py | 213 | 124 | 45 | 44 |
| test_summarization_service.py | 178 | 120 | 36 | 22 |
| test_search_service_v2.py | 183 | 115 | 46 | 22 |
| test_meta_yaml.py | 173 | 114 | 40 | 19 |
| test_user_service.py | 151 | 113 | 22 | 16 |
| test_admin_gc_api.py | 140 | 110 | 17 | 13 |
| test_api_helpers.py | 158 | 105 | 30 | 23 |
| test_auth_service.py | 156 | 105 | 36 | 15 |
| test_rate_limiter.py | 207 | 103 | 79 | 25 |
| test_embedding_service.py | 147 | 92 | 34 | 21 |
| test_prompts.py | 149 | 83 | 30 | 36 |
| test_migration.py | 110 | 75 | 22 | 13 |
| test_llm_tasks.py | 116 | 71 | 29 | 16 |
| test_indexing_tasks.py | 105 | 70 | 23 | 12 |
| test_fixtures.py | 68 | 32 | 21 | 15 |
| test_health.py | 16 | 11 | 5 | 0 |

#### security/ (10 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| test_s09_invisible_consistency.py | 241 | 178 | 31 | 32 |
| test_s06_svg_security.py | 216 | 169 | 29 | 18 |
| test_s04_permission_bypass.py | 209 | 159 | 27 | 23 |
| test_s07_session_regeneration.py | 189 | 140 | 29 | 20 |
| test_s08_info_leakage.py | 190 | 134 | 32 | 24 |
| test_s05_path_traversal.py | 176 | 132 | 20 | 24 |
| test_s01_xss.py | 140 | 108 | 20 | 12 |
| test_performance.py | 151 | 107 | 25 | 19 |
| test_s03_csrf.py | 144 | 101 | 24 | 19 |
| conftest.py | 104 | 73 | 21 | 10 |
| test_s02_external_images.py | 60 | 40 | 10 | 10 |

#### integration/ (4 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| test_search_integration.py | 1,166 | 830 | 177 | 159 |
| test_phase4_integration.py | 854 | 613 | 140 | 101 |
| test_ai_integration.py | 786 | 572 | 116 | 98 |
| test_g5_frontend_backend.py | 622 | 422 | 96 | 104 |

#### system/ (2 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| test_p2_system.py | 479 | 389 | 52 | 38 |
| test_p2_vector.py | 381 | 300 | 56 | 25 |

#### conftest (1 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| conftest.py | 431 | 310 | 82 | 39 |

#### **Backend テスト 合計: 総 23,772 / 有効 17,212**

---

### Frontend 本体 (src/)

#### features/admin/ (13 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| WikiStructureEditor.tsx | 472 | 412 | 42 | 18 |
| LDAPSettings.tsx | 424 | 391 | 32 | 1 |
| AISettings.tsx | 377 | 351 | 21 | 5 |
| ApiKeyManager.tsx | 304 | 285 | 18 | 1 |
| AuditLogViewer.tsx | 284 | 269 | 15 | 0 |
| UserForm.tsx | 287 | 262 | 19 | 6 |
| SystemSettings.tsx | 254 | 230 | 22 | 2 |
| AttachmentGC.tsx | 245 | 218 | 20 | 7 |
| UserList.tsx | 221 | 206 | 11 | 4 |
| ArticleAdminList.tsx | 188 | 177 | 10 | 1 |
| WikiAdminList.tsx | 112 | 99 | 9 | 4 |
| ArticleSearchInput.tsx | 112 | 96 | 8 | 8 |
| FullBackup.tsx | 58 | 51 | 3 | 4 |
| **小計** | **3,338** | **3,047** | **230** | **61** |

#### hooks/ (12 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| useAI.ts | 424 | 355 | 38 | 31 |
| useAdmin.ts | 317 | 269 | 28 | 20 |
| useArticles.ts | 250 | 217 | 15 | 18 |
| useLdapSettings.ts | 210 | 178 | 23 | 9 |
| useApiKeys.ts | 116 | 96 | 15 | 5 |
| useAuditLogs.ts | 86 | 72 | 10 | 4 |
| useWiki.ts | 80 | 72 | 5 | 3 |
| useSearch.ts | 73 | 61 | 5 | 7 |
| useAutoSave.ts | 96 | 55 | 11 | 30 |
| useMermaid.ts | 40 | 21 | 8 | 11 |
| useAuth.ts | 18 | 15 | 2 | 1 |
| useDebounce.ts | 25 | 13 | 4 | 8 |
| **小計** | **1,735** | **1,424** | **164** | **147** |

#### routes/ (14 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| ArticleViewPage.tsx | 224 | 209 | 14 | 1 |
| ArticleListPage.tsx | 203 | 194 | 9 | 0 |
| ArticleHistoryPage.tsx | 149 | 140 | 9 | 0 |
| ArticleEditPage.tsx | 142 | 130 | 11 | 1 |
| WikiPage.tsx | 105 | 92 | 9 | 4 |
| AdminPage.tsx | 94 | 83 | 11 | 0 |
| DashboardPage.tsx | 85 | 81 | 3 | 1 |
| SearchResultsPage.tsx | 89 | 81 | 8 | 0 |
| ArticleCreatePage.tsx | 33 | 31 | 2 | 0 |
| AIChatPage.tsx | 42 | 37 | 4 | 1 |
| LoginPage.tsx | 26 | 23 | 3 | 0 |
| AdminWikisPage.tsx | 18 | 16 | 2 | 0 |
| AdminArticlesPage.tsx | 18 | 16 | 2 | 0 |
| NotFoundPage.tsx | 14 | 13 | 1 | 0 |
| **小計** | **1,242** | **1,146** | **88** | **8** |

#### lib/ (10 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| sanitize.ts | 204 | 125 | 30 | 49 |
| pasteUpload.ts | 181 | 123 | 24 | 34 |
| markdown.ts | 157 | 97 | 25 | 35 |
| markdown-plugins.ts | 176 | 96 | 24 | 56 |
| mermaid.ts | 106 | 66 | 14 | 26 |
| oembed.ts | 102 | 64 | 11 | 27 |
| internal-links.ts | 73 | 50 | 8 | 15 |
| article-embeds.ts | 79 | 49 | 10 | 20 |
| linkAutocomplete.ts | 59 | 41 | 6 | 12 |
| utils.ts | 6 | 5 | 1 | 0 |
| **小計** | **1,143** | **716** | **153** | **274** |

#### features/articles/ (9 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| ArticleForm.tsx | 284 | 250 | 21 | 13 |
| AttachmentUploader.tsx | 260 | 227 | 22 | 11 |
| ConflictDialog.tsx | 130 | 105 | 11 | 14 |
| HistoryList.tsx | 86 | 78 | 4 | 4 |
| DiffViewer.tsx | 74 | 63 | 5 | 6 |
| ArticleMetadata.tsx | 67 | 56 | 5 | 6 |
| ArticleDeleteDialog.tsx | 57 | 51 | 2 | 4 |
| AttachmentList.tsx | 49 | 41 | 3 | 5 |
| attachmentUtils.ts | 30 | 24 | 3 | 3 |
| **小計** | **1,037** | **895** | **76** | **66** |

#### components/ui/ (16 ファイル — shadcn/ui)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| select.tsx | 155 | 145 | 10 | 0 |
| alert-dialog.tsx | 139 | 128 | 11 | 0 |
| table.tsx | 120 | 110 | 10 | 0 |
| dialog.tsx | 119 | 110 | 9 | 0 |
| card.tsx | 76 | 68 | 8 | 0 |
| button.tsx | 57 | 52 | 5 | 0 |
| tabs.tsx | 53 | 47 | 6 | 0 |
| scroll-area.tsx | 46 | 42 | 4 | 0 |
| badge.tsx | 35 | 30 | 5 | 0 |
| separator.tsx | 29 | 26 | 3 | 0 |
| checkbox.tsx | 28 | 25 | 3 | 0 |
| sonner.tsx | 25 | 22 | 3 | 0 |
| label.tsx | 24 | 20 | 4 | 0 |
| textarea.tsx | 22 | 19 | 3 | 0 |
| input.tsx | 22 | 19 | 3 | 0 |
| skeleton.tsx | 15 | 13 | 2 | 0 |
| **小計** | **965** | **876** | **89** | **0** |

#### features/ai/ (4 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| ChatQnA.tsx | 245 | 218 | 21 | 6 |
| ArticleGenerator.tsx | 203 | 181 | 18 | 4 |
| TagSuggestions.tsx | 175 | 161 | 13 | 1 |
| SummarySection.tsx | 100 | 92 | 7 | 1 |
| **小計** | **723** | **652** | **59** | **12** |

#### components/editor/ (4 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| MarkdownPreview.tsx | 118 | 93 | 10 | 15 |
| MarkdownEditor.tsx | 88 | 72 | 5 | 11 |
| SplitView.tsx | 63 | 50 | 7 | 6 |
| TableOfContents.tsx | 48 | 41 | 4 | 3 |
| **小計** | **317** | **256** | **26** | **35** |

#### components/layout/ (3 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| Sidebar.tsx | 92 | 87 | 5 | 0 |
| Header.tsx | 85 | 76 | 9 | 0 |
| AppShell.tsx | 22 | 19 | 2 | 1 |
| **小計** | **199** | **182** | **16** | **1** |

#### api/ (5 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| queryKeys.ts | 80 | 66 | 6 | 8 |
| client.ts | 33 | 24 | 5 | 4 |
| queryClient.ts | 26 | 22 | 2 | 2 |
| csrf.ts | 15 | 7 | 2 | 6 |
| errors.ts | 13 | 8 | 1 | 4 |
| **小計** | **167** | **127** | **16** | **24** |

#### features/auth/ (3 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| LoginForm.tsx | 79 | 73 | 6 | 0 |
| AuthGuard.tsx | 26 | 21 | 4 | 1 |
| AdminGuard.tsx | 13 | 9 | 3 | 1 |
| **小計** | **118** | **103** | **13** | **2** |

#### その他

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| components/wiki/WikiTree.tsx | 114 | 102 | 7 | 5 |
| features/search/SearchResults.tsx | 99 | 87 | 5 | 7 |
| stores/authStore.ts | 91 | 78 | 9 | 4 |
| App.tsx | 79 | 70 | 9 | 0 |
| index.css | 75 | 72 | 3 | 0 |
| stores/uiStore.ts | 24 | 22 | 2 | 0 |
| main.tsx | 10 | 9 | 1 | 0 |
| types/index.ts | 7 | 1 | 0 | 6 |

#### **Frontend 本体 合計: 総 11,483 / 有効 9,865**

---

### Frontend テスト

#### unit/lib テスト

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| test/mocks/handlers.ts | 995 | 878 | 81 | 36 |
| lib/markdown-plugins.test.ts | 275 | 214 | 56 | 5 |
| lib/sanitize.test.ts | 195 | 153 | 37 | 5 |
| lib/markdown.test.ts | 162 | 128 | 30 | 4 |
| lib/oembed.test.ts | 149 | 116 | 31 | 2 |
| lib/article-embeds.test.ts | 122 | 94 | 26 | 2 |
| lib/internal-links.test.ts | 124 | 92 | 27 | 5 |
| lib/pasteUpload.test.ts | 99 | 81 | 15 | 3 |
| lib/mermaid.test.ts | 78 | 59 | 18 | 1 |

#### unit/component テスト

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| admin/WikiStructureEditor.test.tsx | 214 | 153 | 41 | 20 |
| articles/AttachmentUploader.test.tsx | 211 | 181 | 25 | 5 |
| routes/routing.test.tsx | 135 | 118 | 17 | 0 |
| admin/AttachmentGC.test.tsx | 127 | 103 | 15 | 9 |
| ai/AISettings.test.tsx | 123 | 97 | 24 | 2 |
| wiki/WikiTree.test.tsx | 117 | 91 | 18 | 8 |
| admin/SystemSettings.test.tsx | 99 | 77 | 16 | 6 |
| ai/TagSuggestions.test.tsx | 97 | 81 | 15 | 1 |
| admin/ArticleSearchInput.test.tsx | 97 | 73 | 20 | 4 |
| auth/LoginForm.test.tsx | 87 | 69 | 17 | 1 |
| layout/AppShell.test.tsx | 90 | 69 | 13 | 8 |
| articles/ArticleForm.test.tsx | 82 | 64 | 14 | 4 |
| ai/SummarySection.test.tsx | 79 | 62 | 15 | 2 |
| editor/MarkdownEditor.test.tsx | 71 | 56 | 10 | 5 |
| admin/ApiKeyManager.test.tsx | 81 | 58 | 20 | 3 |
| admin/WikiAdminList.test.tsx | 77 | 55 | 18 | 4 |
| auth/AuthGuard.test.tsx | 59 | 53 | 6 | 0 |
| articles/AttachmentList.test.tsx | 58 | 52 | 6 | 0 |
| articles/ArticleList.test.tsx | 60 | 47 | 9 | 4 |
| articles/ConflictDialog.test.tsx | 58 | 45 | 11 | 2 |
| admin/UserList.test.tsx | 64 | 45 | 12 | 7 |
| admin/FullBackup.test.tsx | 53 | 42 | 9 | 2 |
| admin/AuditLogViewer.test.tsx | 56 | 38 | 15 | 3 |
| articles/ArticleDeleteDialog.test.tsx | 55 | 39 | 10 | 6 |
| stores/authStore.test.ts | 51 | 40 | 8 | 3 |
| hooks/useAutoSave.test.ts | 46 | 30 | 9 | 7 |
| api/types.test.ts | 28 | 19 | 4 | 5 |
| App.test.tsx | 21 | 18 | 2 | 1 |

#### E2E テスト (14 ファイル)

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| e2e/helpers/api.ts | 190 | 165 | 12 | 13 |
| e2e/e11-rest-api-v1.spec.ts | 174 | 116 | 26 | 32 |
| e2e/e08-admin-operations.spec.ts | 120 | 81 | 20 | 19 |
| e2e/e10-responsive-design.spec.ts | 100 | 65 | 17 | 18 |
| e2e/e04-version-management.spec.ts | 98 | 60 | 14 | 24 |
| e2e/e07-conflict-detection.spec.ts | 94 | 57 | 16 | 21 |
| e2e/e05-wiki-operation.spec.ts | 82 | 56 | 9 | 17 |
| e2e/e02-article-edit-flow.spec.ts | 84 | 55 | 12 | 17 |
| e2e/e03-attachment-file.spec.ts | 83 | 51 | 11 | 21 |
| e2e/e06-search.spec.ts | 80 | 52 | 14 | 14 |
| e2e/e12-audit-log.spec.ts | 80 | 43 | 13 | 24 |
| e2e/e09-permission-confirmation.spec.ts | 59 | 30 | 13 | 16 |
| e2e/e01-new-user-flow.spec.ts | 55 | 27 | 11 | 17 |
| e2e/fixtures/auth.ts | 23 | 15 | 2 | 6 |

#### テストインフラ

| ファイル | 総 | 有効 | 空 | ※ |
|---------|---:|----:|---:|---:|
| test/helpers.tsx | 35 | 26 | 3 | 6 |
| test/setup.ts | 26 | 19 | 4 | 3 |
| test/mocks/server.ts | 4 | 3 | 1 | 0 |

#### **Frontend テスト 合計: 総 5,982 / 有効 4,611**
