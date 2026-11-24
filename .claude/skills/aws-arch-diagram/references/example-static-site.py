"""実例: 架空の静的サイト (CDK 4 スタック) の AWS 構成図。名前、ドメイン、アカウント番号はすべて架空。

    python3 -I example-static-site.py <出力ディレクトリ>

出力: <out>/infra-diagram.html、<out>/export/<図>.html|.svg|.size (PNG は scripts/render_png.sh <out>/export で作る)。
図は 3 枚: 01-a 簡易版 (production のみ) / 01-b 簡易版 (全環境) / 02 詳細版。
データ (スタック名・ドメイン・設定値) は infra/src の CDK 定義と cdk synth の出力から手で転記する想定。
ヘルパ (scripts/awsdiag.py) はスキルのディレクトリから読む。場所は環境変数 AWS_ARCH_DIAGRAM_DIR (既定は ~/.claude/skills/aws-arch-diagram)。
"""

from __future__ import annotations

import os
import pathlib
import sys

SKILL_DIR = pathlib.Path(os.environ.get("AWS_ARCH_DIAGRAM_DIR") or pathlib.Path.home() / ".claude" / "skills" / "aws-arch-diagram")
sys.path.insert(0, str(SKILL_DIR / "scripts"))
from awsdiag import (  # noqa: E402
    cloud_frame,
    edge,
    export_figures,
    label2,
    lines,
    manual_box,
    page,
    region_frame,
    sbox,
    stack_band,
    text,
    use,
)

OUT = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "out")

# ============================================================
# 02 詳細版: スタックごとの帯に設定値まで書く
# ============================================================

SITE_STACKS = [
    {
        "name": "StaticSiteProduction",
        "env": "Environment=Production",
        "y0": 290,
        "fn": [
            ("tb", "CloudFront Function"),
            ("tm", "UrlRewriteFunction"),
            ("ts", "viewer-request・cloudfront-js-2.0"),
            ("ts", "index.html 補完・apex->www 301"),
            ("ts", "旧 URL からの 302 (redirects.ts)"),
        ],
        "dist": [
            ("tb", "CloudFront Distribution"),
            ("tm", "www.example.com / example.com"),
            ("ts", "Alias は Route 53 の ALIAS・cert: ACM (us-east-1)・IPv6 on"),
            ("ts", "default -> SiteBucket (OAC)・CachingOptimized・compress"),
            ("ts", "/files/* -> AssetsBucket (OAC)・CachingDisabled"),
            ("ts", "redirect-to-https・PriceClass 200・403/404 -> /404.html"),
            ("ts", "ResponseHeadersPolicy: FilesPolicy (Cache-Control: no-cache)"),
        ],
        "site": [
            ("tm", "example-site-production"),
            ("ts", "SiteBucket・BlockPublicAccess ALL・SSE-S3・enforceSSL・RETAIN"),
            ("ts", "BucketPolicy: OAC からの GetObject のみ"),
        ],
        "assets": [
            ("tm", "example-assets-production"),
            ("ts", "AssetsBucket・versioned・RETAIN・資料 PDF (CI 対象外、手動 aws s3 cp)"),
            ("ts", "BucketPolicy: OAC からの GetObject のみ"),
        ],
    },
    {
        "name": "StaticSiteStaging",
        "env": "Environment=Staging",
        "y0": 496,
        "fn": [
            ("tb", "CloudFront Function"),
            ("tm", "UrlRewriteFunction"),
            ("ts", "viewer-request・cloudfront-js-2.0"),
            ("ts", "index.html 補完・apex->www 301"),
            ("ts", "旧 URL からの 302 (redirects.ts)"),
            ("ts", "許可 IP 以外へ 403 (SSM の IP を埋め込み)"),
        ],
        "dist": [
            ("tb", "CloudFront Distribution"),
            ("tm", "stg.example.com"),
            ("ts", "Alias は Route 53 の ALIAS・cert: ACM (us-east-1)・IPv6 off"),
            ("ts", "default -> SiteBucket (OAC)・CachingOptimized・compress"),
            ("ts", "/files/* -> AssetsBucket (OAC)・CachingDisabled"),
            ("ts", "redirect-to-https・PriceClass 200・403/404 -> /404.html"),
            ("ts", "ResponseHeadersPolicy: NoIndexPolicy (X-Robots-Tag noindex)・FilesPolicy"),
        ],
        "site": [
            ("tm", "example-site-staging"),
            ("ts", "SiteBucket・BlockPublicAccess ALL・SSE-S3・enforceSSL・RETAIN"),
            ("ts", "BucketPolicy: OAC からの GetObject のみ"),
        ],
        "assets": [
            ("tm", "example-assets-staging"),
            ("ts", "AssetsBucket・versioned・RETAIN・資料 PDF (CI 対象外、手動 aws s3 cp)"),
            ("ts", "BucketPolicy: OAC からの GetObject のみ"),
        ],
    },
]

PREVIEW_STACK = {
    "name": "StaticSitePreview",
    "env": "Environment=Development",
    "y0": 702,
    "fn": [
        ("tb", "CloudFront Function"),
        ("tm", "PreviewRouterFunction"),
        ("ts", "viewer-request・cloudfront-js-2.0"),
        ("ts", "Host の <ref_slug> を S3 prefix に解決"),
        ("ts", "index.html 補完"),
        ("ts", "許可 IP 以外へ 403 (SSM の IP を埋め込み)"),
    ],
    "dist": [
        ("tb", "CloudFront Distribution"),
        ("tm", "*.preview.example.com"),
        ("ts", "Alias は Route 53 の ALIAS・cert: ACM (us-east-1)・IPv6 off"),
        ("ts", "default -> PreviewBucket (OAC)・CachingDisabled・compress"),
        ("ts", "redirect-to-https・PriceClass 200"),
        ("ts", "ResponseHeadersPolicy: NoIndexPolicy (X-Robots-Tag noindex)"),
    ],
    "site": [
        ("tm", "example-preview"),
        ("ts", "PreviewBucket・BlockPublicAccess ALL・SSE-S3・enforceSSL・DESTROY"),
        ("ts", "BucketPolicy: OAC からの GetObject のみ"),
        ("ts", "/<ref_slug>/ ごとに topic ブランチの dist (CI が sync・掃除)"),
    ],
}

CI_USERS = [
    {
        "x": 150,
        "title": "Deploy",
        "names": "User / Group / Policy  StaticSite-Deploy",
        "perm": [
            "s3 ListBucket / Get / Put / DeleteObject: site-production, site-staging",
            "cloudfront:CreateInvalidation: production / staging の Distribution",
            "CI の変数 AWS_* (masked + protected)",
        ],
    },
    {
        "x": 575,
        "title": "PreviewDeploy",
        "names": "User / Group / Policy  StaticSite-PreviewDeploy",
        "perm": [
            "s3 ListBucket / Get / Put / DeleteObject: example-preview",
            "cloudfront:CreateInvalidation: preview の Distribution",
            "CI の変数 PREVIEW_AWS_* (非 protected)",
        ],
    },
    {
        "x": 1000,
        "title": "InfraDiff (読み取り専用)",
        "names": "User / Group / Policy  StaticSite-InfraDiff",
        "perm": [
            "cloudformation DescribeStacks / GetTemplate: StaticSite*",
            "ssm:GetParameter + kms:Decrypt (SSM 経由のみ)",
            "CI の変数 INFRA_DIFF_AWS_* (非 protected)",
        ],
    },
]


def site_band(s: dict) -> str:
    y0 = s["y0"]
    return "\n".join(
        [
            stack_band(60, y0, 1320, 190, s["name"], s["env"]),
            # Function (左) -破線-> Distribution (中央) -> S3 x2 (右)。説明文はアイコンの下か右
            use("cffunc", 300, y0 + 42, 36),
            lines(80, y0 + 52, s["fn"]),
            edge([(336, y0 + 60), (380, y0 + 60)], "d", dashed=True),
            use("cloudfront", 380, y0 + 32, 56),
            lines(380, y0 + 104, s["dist"], 13),
            use("s3", 830, y0 + 40, 40),
            lines(880, y0 + 56, s["site"]),
            use("s3", 830, y0 + 110, 40),
            lines(880, y0 + 126, s["assets"]),
            edge([(436, y0 + 54), (830, y0 + 54)], "d"),
            text(630, y0 + 48, "default behavior (OAC)", "lbl", "middle"),
            # 2 本目は説明文の右 (x=760) を縦に通して下のバケットへ
            edge([(436, y0 + 70), (760, y0 + 70), (760, y0 + 130), (830, y0 + 130)], "d"),
            text(600, y0 + 84, "/files/* behavior (OAC)", "lbl", "middle"),
        ]
    )


def preview_band(s: dict) -> str:
    y0 = s["y0"]
    return "\n".join(
        [
            stack_band(60, y0, 1320, 190, s["name"], s["env"]),
            use("cffunc", 300, y0 + 42, 36),
            lines(80, y0 + 52, s["fn"]),
            edge([(336, y0 + 60), (380, y0 + 60)], "d", dashed=True),
            use("cloudfront", 380, y0 + 32, 56),
            lines(380, y0 + 104, s["dist"], 13),
            use("s3", 830, y0 + 40, 40),
            lines(880, y0 + 56, s["site"]),
            edge([(436, y0 + 60), (830, y0 + 60)], "d"),
            text(630, y0 + 54, "default behavior (OAC)", "lbl", "middle"),
        ]
    )


def ci_band() -> str:
    y0 = 908
    out = [
        stack_band(60, y0, 1320, 120, "StaticSiteCiAccess", "Environment=Production"),
        text(1370, y0 + 21, "アクセスキーは CDK で作らず手動発行 (CI の変数へ登録)", "ts", "end"),
        use("iam", 76, y0 + 44, 48),
        text(100, y0 + 108, "IAM", "tb", "middle"),
    ]

    for u in CI_USERS:
        x = u["x"]
        out += [
            f'<rect class="card" x="{x}" y="{y0 + 34}" width="{405 if x < 1000 else 370}" height="80" rx="4"/>',
            use("key", x + 8, y0 + 42, 26),
            text(x + 42, y0 + 52, u["title"], "tb"),
            text(x + 42, y0 + 66, u["names"], "tm9"),
            lines(x + 42, y0 + 82, [("ts", p) for p in u["perm"]], 13),
        ]

    return "\n".join(out)


detail_svg = f"""
<svg class="diagram" viewBox="0 0 1600 1080" role="img" aria-label="CDK 4 スタック (SiteProduction / SiteStaging / Preview / CiAccess) の AWS リソース構成。各 site スタックは CloudFront Distribution と viewer-request Function、OAC 経由の S3 バケット 2 つ (site / assets) を持ち、Preview は単一バケット、CiAccess は役割別の IAM 3 点セットを持つ。Route 53 と ACM、SSM パラメータ、CDK bootstrap は手動管理。">
<rect x="0" y="0" width="1600" height="1080" fill="url(#grid2)"/>

<g transform="translate(160 0)">
{cloud_frame(20, 20, 1400, 1040, "アカウント 1234-5678-9012 (複数システムで共用)・CDK app: infra/ (bootstrap qualifier sitecdk)")}

{manual_box(40, 60, 1360, 96, "手動管理 (CDK 外)・global / us-east-1")}
{use("route53", 60, 84, 48)}
{text(120, 100, "Route 53 hosted zone  example.com", "tb")}
{text(120, 115, "ALIAS (手動): www.example.com / example.com -> production、stg -> staging、*.preview -> preview の各 Distribution", "ts")}
{text(120, 129, "レコードは CDK 管理外。ドメインの登録は別のレジストラ", "ts")}
{use("acm", 760, 84, 48)}
{text(820, 100, "ACM 証明書 (us-east-1)", "tb")}
{text(820, 115, "SAN: example.com / *.example.com / *.preview.example.com", "ts")}
{text(820, 129, "手動発行し ARN を CDK へ渡す。3 Distribution で共用、検証 CNAME 恒久設置で自動更新", "ts")}

{region_frame(40, 170, 1360, 874, "ap-northeast-1 (東京)", "CloudFront Distribution / Function は global サービスだが、所属する CloudFormation スタックはこのリージョン")}

{manual_box(60, 204, 1320, 68, "手動管理 (CDK 外)")}
{use("ssm", 80, 224, 40)}
{text(130, 238, "SSM Parameter Store", "tb")}
{text(130, 252, "/StaticSite/allowed-viewer-ips (SecureString、拠点ラベル付き)", "tm")}
{text(130, 266, "stg / preview の閲覧許可 IP。just レシピが synth 時に読み、Function コードへ埋め込む", "ts")}
{use("cfn", 760, 224, 40)}
{text(810, 238, "CDK bootstrap  CDKToolkit-StaticSite", "tb")}
{text(810, 252, "qualifier sitecdk (他システムのデフォルト系統と分離)", "ts")}
{text(810, 266, "deploy は手元から (ブランチのガード付き)。MR では cdk diff のみ", "ts")}

{site_band(SITE_STACKS[0])}
{site_band(SITE_STACKS[1])}
{preview_band(PREVIEW_STACK)}
{ci_band()}
</g>

{use("users", 40, 318, 64)}
{text(72, 400, "ユーザ (ブラウザ)", "sl", "middle")}
{text(72, 413, "インターネット経由", "sls", "middle")}
{edge([(104, 350), (150, 350), (150, 280), (568, 280), (568, 322)], "d")}
{text(156, 318, "HTTPS", "lbl")}
{edge([(72, 318), (72, 108), (220, 108)], "d")}
{text(140, 102, "名前解決", "lbl", "middle")}
</svg>
"""

# ============================================================
# 01 簡易版: アイコン + サービス名だけ。1 スタック = 青破線の枠 600x240
# ============================================================

BX = 380  # スタック枠の左端。左 180px に利用者、180..380 に Route 53 / ACM
SIMPLE_BOXES = [
    {"by": 50, "name": "SiteProduction", "domain": "www.example.com / example.com", "assets": True},
    {"by": 320, "name": "SiteStaging", "domain": "stg.example.com (IP 制限)", "assets": True},
    {"by": 590, "name": "Preview", "domain": "*.preview.example.com (IP 制限)", "assets": False},
]


def simple_box(b: dict) -> str:
    """枠内は 2 行 2 列: 上段 [CloudFront Functions] [S3 assets]、下段 [CloudFront] [S3 site]。"""
    by = b["by"]
    bx = BX
    cf_cx = bx + 72
    out = [
        sbox(bx, by, 600, 240, b["name"]),
        use("cffunc", bx + 44, by + 36, 56),
        text(bx + 112, by + 60, "CloudFront Functions", "sl"),
        text(bx + 112, by + 73, "viewer-request", "sls"),
        edge([(cf_cx, by + 92), (cf_cx, by + 134)], dashed=True, arrow=False),
        use("cloudfront", bx + 40, by + 134, 64),
        label2(cf_cx, by + 214, "Amazon CloudFront", b["domain"]),
        use("s3", bx + 480, by + 134, 64),
    ]

    if b["assets"]:
        out += [
            label2(bx + 512, by + 214, "Amazon S3", "site (dist)"),
            use("s3", bx + 480, by + 32, 64),
            label2(bx + 512, by + 112, "Amazon S3", "assets (資料 PDF)"),
            edge([(bx + 104, by + 172), (bx + 480, by + 172)]),
            text(bx + 292, by + 186, "default", "slbl", "middle"),
            edge([(bx + 104, by + 160), (bx + 292, by + 160), (bx + 292, by + 64), (bx + 480, by + 64)]),
            text(bx + 386, by + 58, "/files/*", "slbl", "middle"),
        ]
    else:
        out += [
            label2(bx + 512, by + 214, "Amazon S3", "preview (ブランチ別 prefix)"),
            edge([(bx + 104, by + 166), (bx + 480, by + 166)]),
            text(bx + 292, by + 180, "default", "slbl", "middle"),
        ]

    return "\n".join(out)


# 利用者は AWS Cloud の枠外 (左)。名前解決は Route 53 へ実線、HTTPS は production の CloudFront へ実線。
# Route 53 / ACM からの紐付け (ALIAS / 証明書) は破線で、x=360 / x=330 の縦線から各 CloudFront へ分岐する
left_common = f"""
{use("users", 36, 176, 64)}
{label2(68, 258, "ユーザ (ブラウザ)", "インターネット経由")}
{use("route53", 240, 60, 64)}
{label2(272, 142, "Amazon Route 53", "example.com")}
{edge([(100, 212), (BX + 40, 212)])}
{text(272, 206, "HTTPS", "slbl", "middle")}
{edge([(100, 196), (130, 196), (130, 92), (240, 92)])}
{text(185, 86, "名前解決", "slbl", "middle")}
{text(332, 86, "ALIAS", "slbl", "middle")}
"""

simple_all_svg = f"""
<svg class="diagram diagram-s" viewBox="0 0 1400 1020" role="img" aria-label="概要: Route 53 と ACM 証明書が production / staging / preview の 3 つの CloudFront に紐付き、各 CloudFront は CloudFront Functions を通して S3 (site と assets、preview は単一) から配信する。右の IAM ユーザ 3 つが CI から S3 への sync と cdk diff を担う。">
<rect x="0" y="0" width="1400" height="1020" fill="#ffffff"/>
{cloud_frame(180, 20, 1200, 980, "アカウント 1234-5678-9012")}
<g transform="translate(0 40)">
{left_common}
{use("acm", 240, 462, 64)}
{label2(272, 544, "AWS Certificate Manager", "us-east-1・3 SAN")}
{edge([(304, 92), (360, 92), (360, 748)], dashed=True, arrow=False)}
{edge([(360, 196), (BX + 40, 196)], dashed=True)}
{edge([(360, 478), (BX + 40, 478)], dashed=True)}
{edge([(360, 748), (BX + 40, 748)], dashed=True)}
{edge([(304, 494), (BX + 40, 494)], dashed=True)}
{edge([(330, 228), (330, 764)], dashed=True, arrow=False)}
{edge([(330, 228), (BX + 40, 228)], dashed=True)}
{edge([(330, 764), (BX + 40, 764)], dashed=True)}
{text(390, 508, "証明書", "slbl", "middle")}

{simple_box(SIMPLE_BOXES[0])}
{simple_box(SIMPLE_BOXES[1])}
{simple_box(SIMPLE_BOXES[2])}

{sbox(1040, 50, 300, 780, "CiAccess")}
{use("iam", 1158, 90, 64)}
{label2(1190, 170, "AWS IAM", "CI 用ユーザ x3")}
{use("key", 1162, 330, 56)}
{label2(1190, 404, "Deploy", "stg / main の CI")}
{use("key", 1162, 540, 56)}
{label2(1190, 614, "InfraDiff", "cdk diff (読み取り)")}
{use("key", 1162, 728, 56)}
{label2(1190, 802, "PreviewDeploy", "topic ブランチの CI")}

{edge([(1162, 358), (1010, 358)], arrow=False)}
{edge([(1010, 216), (1010, 486)], arrow=False)}
{edge([(1010, 216), (944, 216)])}
{edge([(1010, 486), (944, 486)])}
{text(1086, 352, "s3 sync", "slbl", "middle")}
{edge([(1162, 756), (944, 756)])}
{text(1053, 750, "s3 sync", "slbl", "middle")}

{edge([(1218, 568), (1290, 568), (1290, 892), (1222, 892)], dashed=True)}
{text(1296, 740, "cdk diff", "slbl")}
{use("cfn", 1158, 860, 64)}
{label2(1190, 942, "AWS CloudFormation", "CDK 4 スタック")}
</g>
</svg>
"""

simple_prod_svg = f"""
<svg class="diagram diagram-s" viewBox="0 0 1400 480" role="img" aria-label="production のみの概要: Route 53 と ACM 証明書が www.example.com の CloudFront に紐付き、CloudFront Functions を通して S3 の site バケットと assets バケットから配信する。右の IAM ユーザ Deploy が CI から site バケットへ sync する。">
<rect x="0" y="0" width="1400" height="480" fill="#ffffff"/>
{cloud_frame(180, 20, 1200, 440, "アカウント 1234-5678-9012")}
<g transform="translate(0 40)">
{left_common}
{edge([(304, 92), (360, 92), (360, 196), (BX + 40, 196)], dashed=True)}

{use("acm", 240, 300, 64)}
{label2(272, 382, "AWS Certificate Manager", "us-east-1・3 SAN")}
{edge([(304, 332), (330, 332), (330, 228), (BX + 40, 228)], dashed=True)}
{text(324, 284, "証明書", "slbl", "end")}

{simple_box(SIMPLE_BOXES[0])}

{sbox(1040, 50, 300, 240, "CiAccess")}
{use("iam", 1158, 78, 56)}
{label2(1186, 150, "AWS IAM", "CI 用ユーザ")}
{use("key", 1162, 188, 56)}
{label2(1190, 262, "Deploy", "main の CI が使う")}
{edge([(1162, 216), (944, 216)])}
{text(1053, 210, "s3 sync", "slbl", "middle")}
</g>
</svg>
"""

# ============================================================
# ページと書き出し
# ============================================================

FIGURES = [
    {
        "num": "01-a",
        "heading": "簡易版 (production のみ)",
        "svg": simple_prod_svg,
        "caption": "本番配信に関わるものだけ。fx は CloudFront Functions (viewer-request)。破線は設定の紐付け (ALIAS / 証明書)、実線はリクエストと CI の書き込み。",
        "img": "infra-01a-production",
    },
    {
        "num": "01-b",
        "heading": "簡易版 (全環境)",
        "svg": simple_all_svg,
        "caption": "production / staging / preview の 3 環境と CI 用 IAM。破線は設定の紐付け (ALIAS / 証明書 / cdk diff)、実線はリクエストと CI の書き込み。すべて ap-northeast-1 の CloudFormation スタックで、Route 53 と ACM は手動管理。",
        "img": "infra-01b-all",
    },
    {
        "num": "02",
        "heading": "詳細版",
        "svg": detail_svg,
        "caption": "S3 は BlockPublicAccess で閉じ、CloudFront から OAC で読む。各 Distribution は viewer-request の Function で index.html 補完と転送を行い、stg / preview は許可 IP 以外へ 403 を返す。CiAccess の IAM は役割ごとに Group / User / ManagedPolicy の 3 点セット。",
        "img": "infra-02-detail",
    },
]

html_page = page(
    title="静的サイト AWS 構成図",
    eyebrow="static-site / infra (CDK) / 2026-01-10 時点",
    h1="静的サイト (架空の例) の AWS 構成図",
    lead="infra/src の CDK 定義 (main.ts / site-stack.ts / preview-stack.ts / ci-access-stack.ts) と cdk synth の出力から起こした。01 は全体像をアイコンだけで追う簡易版、02 はリソースの設定値まで書いた詳細版。",
    figures=FIGURES,
    notes=[
        "全リソースに Project=StaticSite / Owner / Environment の 3 タグ (組織のタグ付けの方針)。Environment は各スタック枠の右に記載。",
        "CDK の出力 (バケット名 / Distribution ID / IAM ユーザ名) を CI の変数 <code>SITE_BUCKET_*</code> <code>CLOUDFRONT_DIST_*</code> <code>PREVIEW_BUCKET</code> と各アクセスキーに登録して配線する。",
        "同じアカウントには別システムの EC2 もあるが、このシステムの CDK 管理外のため図には含めていない。",
    ],
)

OUT.mkdir(parents=True, exist_ok=True)
(OUT / "infra-diagram.html").write_text(html_page, encoding="utf-8")
export_figures(OUT / "export", {f["img"]: f["svg"] for f in FIGURES})
print(f"wrote {OUT / 'infra-diagram.html'} and {OUT / 'export'}/")
