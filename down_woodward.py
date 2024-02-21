import requests
import pandas as pd
import shutil
from io import StringIO
import sys
import json
import re
from typing import Union, Dict
import random
import time


def generate_jquery_string():
    """
    根据: https://woodward.library.ubc.ca/wp-content/plugins/enable-jquery-migrate-helper/js/jquery/jquery-1.12.4-wp.js?ver=1.12.4-wp
    的响应内容生成 jQuery 字符串
    js的代码: "jQuery" + (m + Math.random()).replace(/\D/g, "")
    这里改写为Python代码
    """
    m = "1.12.4"  # 从响应内容中获取, 版本号
    combined_string = m + str(random.random())
    # 将m转换为字符串，并去除非数字字符
    filtered_string = "".join(filter(str.isdigit, combined_string))
    jquery_string = "jQuery" + filtered_string
    return jquery_string


def parse_jsonp(jsonp_str: str) -> Union[Dict, None]:
    """
    解析 JSONP 字符串, 返回 JSON 对象
    Args:
        jsonp_str: JSONP 字符串
    Returns:
        JSON 对象
    """
    # 去除 JSONP 字符串的前后括号
    jsonp_str = jsonp_str[jsonp_str.find("(") + 1 : jsonp_str.rfind(")")]
    # 转换为 JSON 格式
    try:
        json_data = json.loads(jsonp_str)
        return json_data
    except json.JSONDecodeError as e:
        print(f"Error decoding JSONP string: {e}")
        return None


headers = {
    "Accept": "*/*",
    "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6",
    "Cache-Control": "no-cache",
    "Connection": "keep-alive",
    "Pragma": "no-cache",
    "Referer": "https://woodward.library.ubc.ca/",
    "Sec-Fetch-Dest": "script",
    "Sec-Fetch-Mode": "no-cors",
    "Sec-Fetch-Site": "same-site",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36 Edg/121.0.0.0",
    "sec-ch-ua": '"Not A(Brand";v="99", "Microsoft Edge";v="121", "Chromium";v="121"',
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": '"Windows"',
}


if __name__ == "__main__":
    jquery_string = generate_jquery_string()
    now_time = int(time.time() * 1000)
    params = {"callback": f"{jquery_string}_{now_time}", "_": str(now_time)}

    url = "https://journal-abbreviations.library.ubc.ca/dump.php"
    response = requests.get(url, headers=headers, params=params)
    if response.status_code != 200:
        print(f"Failed to get data from {url}.")
        sys.exit(1)

    jsonp_str = response.text

    json_data = parse_jsonp(jsonp_str)
    if json_data is None:
        print("Failed to parse JSONP.")
        sys.exit(1)

    html_data = json_data["html"]
    df = pd.read_html((StringIO(html_data)))  # returns a list of DataFrames
    if len(df) == 0:
        print("No data found.")
        sys.exit(1)

    print(f"type(df): {type(df)}")
    print(f"len(df): {len(df)}")

    # 数据清理
    data = (
        df[0]  # 获取第一个DataFrame
        .dropna()  # 删除含有NaN的所有行
        .drop_duplicates()  # 删除重复行
        .query('Abbreviation != "top"')  # 删除 Abbreviation = top 的行
        .query(
            'not Abbreviation.str.contains("^[0-9A-Z] top$")', engine="python"
        )  # 删除 Abbreviation = * top 的行
        .reset_index(drop=True)  # 重置索引
    )

    print(data.head(10))  # 查看前10行数据

    # 保存数据
    df = data[["Title", "Abbreviation"]]
    if not df.empty:
        df.to_csv(
            "woodward_library_new.csv",
            index=False,
            header=False,
            sep=",",
            quoting=1,
            quotechar='"',
            encoding="utf-8-sig",
        )
        print(f"数据共有{df.shape[0]}行, 保存在./woodward_library_new.csv 文件中!!!")
