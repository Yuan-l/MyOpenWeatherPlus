#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""城市目录生成物的数据层回归测试（无需 Xcode，可直接跑）。

用法：python3 components/MyOpenWeatherPlus/tools/test_city_catalog_data.py
"""

from __future__ import annotations

import re
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
SOURCE = HERE.parent / "Classess" / "Helpers" / "TBCityCatalogData.m"

RECORD = re.compile(
    r'\{"([^"]*)", "([^"]*)", "([^"]*)", "([^"]*)", "([^"]*)", '
    r'"([^"]*)", "([^"]*)", "([^"]*)"\}'
)


class CatalogDataTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.records = RECORD.findall(SOURCE.read_text(encoding="utf-8"))
        cls.by_id = {row[0]: row for row in cls.records}

    def test_has_full_city_list(self) -> None:
        self.assertGreater(len(self.records), 3000)

    def test_ids_unique(self) -> None:
        self.assertEqual(len(self.by_id), len(self.records))

    def test_every_record_has_coordinates_and_timezone(self) -> None:
        for row in self.records:
            cid, name, en, adm1, adm2, lat, lon, tz = row
            self.assertTrue(cid and name and en and tz, row)
            float(lat), float(lon)

    def test_major_cities_present(self) -> None:
        for name in ("北京", "上海", "广州", "深圳", "杭州", "成都", "武汉", "西安"):
            self.assertTrue(any(row[1] == name for row in self.records), name)

    def test_hot_city_ids_present(self) -> None:
        for cid in ("101010100", "101020100", "101280101", "101280601",
                    "101210101", "101270101", "101040100", "101200101"):
            self.assertIn(cid, self.by_id, cid)

    def test_search_coverage(self) -> None:
        """模拟 ObjC 的检索：中文名 / 拼音 / 省份都应命中多个城市。"""
        self.assertGreater(sum(1 for r in self.records if "广州" in r[1]), 0)
        self.assertGreater(sum(1 for r in self.records if r[2].lower().startswith("guangzhou")), 0)
        self.assertGreater(sum(1 for r in self.records if "广东" in r[3]), 10)
        self.assertGreater(sum(1 for r in self.records if "浙江" in r[3]), 10)


if __name__ == "__main__":
    print(f"解析 {SOURCE.name}：{len(RECORD.findall(SOURCE.read_text(encoding='utf-8')))} 条记录")
    unittest.main(verbosity=2)
