#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成 MyOpenWeatherPlus 组件内置的离线城市目录（TBCityCatalogData.h/.m）。

数据源：和风天气官方「常用地区列表」China-City-List-latest.csv
        https://github.com/qwd/LocationList

为什么把城市表编译进组件：
  1. 城市搜索/添加/切换不该依赖网络；网络失败也要能把城市加进去；
  2. 组件自带数据才能被其它 App 复用，不需要宿主额外塞 plist；
  3. 用官方 Location_ID 直接请求天气，省掉「搜索 → 再 GEO 反查」这一跳。

用法：
    python3 components/MyOpenWeatherPlus/tools/build_city_catalog.py
    python3 components/MyOpenWeatherPlus/tools/build_city_catalog.py --csv /path/to/local.csv

生成物会被 MyOpenWeatherPlus.podspec 的 source_files 自动编入，无需 pod install。
"""

from __future__ import annotations

import argparse
import csv
import io
import re
import sys
import urllib.request
from pathlib import Path

DEFAULT_CSV_URL = "https://raw.githubusercontent.com/qwd/LocationList/master/China-City-List-latest.csv"
COMPONENT = Path(__file__).resolve().parents[1]
HEADER_PATH = COMPONENT / "Classess" / "Helpers" / "TBCityCatalogData.h"
SOURCE_PATH = COMPONENT / "Classess" / "Helpers" / "TBCityCatalogData.m"

EXPECTED_COLUMNS = [
    "Location_ID", "Location_Name_EN", "Location_Name_ZH", "ISO_3166_1",
    "Country_Region_EN", "Country_Region_ZH", "Adm1_Name_EN", "Adm1_Name_ZH",
    "Adm2_Name_EN", "Adm2_Name_ZH", "Timezone", "Latitude", "Longitude", "AD_code",
]


def c_string(value: str) -> str:
    escaped = (value.replace("\\", "\\\\")
                    .replace('"', '\\"')
                    .replace("\n", "\\n")
                    .replace("\r", "\\r")
                    .replace("\t", "\\t"))
    return '"%s"' % escaped


def read_rows(csv_path: Path | None) -> tuple[str, list[dict]]:
    if csv_path:
        text = csv_path.read_text(encoding="utf-8-sig")
    else:
        request = urllib.request.Request(DEFAULT_CSV_URL,
                                         headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(request, timeout=30) as response:
            text = response.read().decode("utf-8-sig")

    lines = text.splitlines()
    version = lines[0].strip().rstrip(",").strip() if lines else "unknown"
    # 第一行是版本横幅，第二行才是表头
    reader = csv.DictReader(io.StringIO("\n".join(lines[1:])))
    missing = [name for name in EXPECTED_COLUMNS if name not in (reader.fieldnames or [])]
    if missing:
        raise SystemExit(f"CSV 表头缺少字段：{missing}；实际表头={reader.fieldnames}")
    return version, list(reader)


def build_records(rows: list[dict]) -> tuple[list[tuple[str, ...]], list[str]]:
    records: list[tuple[str, ...]] = []
    problems: list[str] = []
    seen: set[str] = set()
    for index, row in enumerate(rows, start=3):
        cid = (row.get("Location_ID") or "").strip()
        name = (row.get("Location_Name_ZH") or "").strip()
        en = (row.get("Location_Name_EN") or "").strip()
        adm1 = (row.get("Adm1_Name_ZH") or "").strip()
        adm2 = (row.get("Adm2_Name_ZH") or "").strip()
        lat = (row.get("Latitude") or "").strip()
        lon = (row.get("Longitude") or "").strip()
        tz = (row.get("Timezone") or "").strip()
        # 和风的部分行政区 ID 是十六进制风格（如 1B6D3 / F21E4），不能只按纯数字过滤
        if not cid or not name or not re.fullmatch(r"[A-Za-z0-9]+", cid):
            problems.append(f"line {index}: 无效 Location_ID/名称")
            continue
        if cid in seen:
            problems.append(f"line {index}: 重复 Location_ID {cid}")
            continue
        try:
            float(lat), float(lon)
        except ValueError:
            problems.append(f"line {index}: 无效坐标 {lat},{lon}")
            continue
        seen.add(cid)
        records.append((cid, name, en or name, adm1, adm2, lat, lon, tz or "Asia/Shanghai"))
    return records, problems


def write_header(version: str) -> None:
    HEADER_PATH.write_text(f"""//
//  TBCityCatalogData.h
//  MyOpenWeatherPlus
//
//  由 tools/build_city_catalog.py 生成，请勿手工编辑。
//  数据源：{version}
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct {{
    const char *cid;         // 和风 Location_ID，直接用于天气接口
    const char *name;        // 中文名
    const char *englishName; // 英文名/拼音，支持拼音检索
    const char *adm1;        // 省级行政区
    const char *adm2;        // 地级行政区
    const char *lat;
    const char *lon;
    const char *timezone;
}} TBCityCatalogRecord;

extern const TBCityCatalogRecord TBCityCatalogRecords[];
extern const NSUInteger TBCityCatalogRecordCount;
extern NSString * const TBCityCatalogVersion;

NS_ASSUME_NONNULL_END
""", encoding="utf-8")


def write_source(version: str, records: list[tuple[str, ...]]) -> None:
    lines = [
        "//",
        "//  TBCityCatalogData.m",
        "//  MyOpenWeatherPlus",
        "//",
        f"//  由 tools/build_city_catalog.py 生成，请勿手工编辑。共 {len(records)} 个城市。",
        f"//  数据源：{version}",
        "//",
        "",
        '#import "TBCityCatalogData.h"',
        "",
        f"NSString * const TBCityCatalogVersion = @\"{version}\";",
        "",
        "const TBCityCatalogRecord TBCityCatalogRecords[] = {",
    ]
    for record in records:
        fields = ", ".join(c_string(value) for value in record)
        lines.append("    {%s}," % fields)
    lines += [
        "};",
        "",
        "const NSUInteger TBCityCatalogRecordCount = "
        "sizeof(TBCityCatalogRecords) / sizeof(TBCityCatalogRecords[0]);",
        "",
    ]
    SOURCE_PATH.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="生成组件内置城市目录")
    parser.add_argument("--csv", type=Path, default=None, help="本地 CSV；缺省时下载官方最新列表")
    args = parser.parse_args()

    version, rows = read_rows(args.csv)
    records, problems = build_records(rows)
    if not records:
        raise SystemExit("没有生成任何城市记录，请检查数据源")
    write_header(version)
    write_source(version, records)
    print(f"数据源：{version}")
    print(f"输入 {len(rows)} 行，生成 {len(records)} 个城市，跳过 {len(problems)} 条异常")
    print(f"输出：{HEADER_PATH.relative_to(COMPONENT)}")
    print(f"      {SOURCE_PATH.relative_to(COMPONENT)}")
    if problems:
        print("跳过示例：", problems[:5], file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
