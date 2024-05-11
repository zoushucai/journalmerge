## 数据来源
- [JabRef/abbrv.jabref.org](https://github.com/JabRef/abbrv.jabref.org/)
- [the university of british Columbia](https://woodward.library.ubc.ca/woodward/research-help/journal-abbreviations/)

只做数据的搬运工, 按照某些规则, 对数据进行筛选,去重等工作, 形成一张缩写对照表. 

## 利用子模块

```bash
git submodule add https://github.com/JabRef/abbrv.jabref.org.git metadata
git submodule update --remote

git clone --recursive https://github.com/zoushucai/journalmerge.git

git submodule update --init --recursive
```

## 合并期刊简写

- 先执行 `python ./down_woodward.py`, 会产生 `woodward_library_new.csv` 文件

- 然后执行 `python ./copyfile.py`,

  - 会把当前文件夹下的 `./woodward_library_new.csv` 文件与 `./woodward_library.csv` 文件进行比较, 如果不一样,则拷贝到 `./woodward_library.csv`,

  - 同时会执行 `Rscript ./combine_journal_lists.R`, 会生成一个 `data_new.ts` , `data_new.csv` 以及 `R/sysdata.rda `文件,

  - 然后运行 比较 `data_new.ts` 和 `data.ts` 是否相同, 如果相同,则不拷贝, 如果不同,则用 `data_new.ts` 替换 `data.ts`

最后把 `data.ts` 和 `R/sysdata.rda` 传给其他的仓库

- `data.ts` 用于 zotero-journalabbr 仓库

- `R/sysdata.rda` 用于 `journalabbr` 仓库

## 说明

- 由于本仓库涉及爬虫

github action 脚本运行的步骤, 本质运行 `bash ./main.sh`

- `clear_data.js` 会把 `data_new.ts` 拷贝成 `data_new.js`, 然后删除 `iso4` 标准相同, 生成` datanew.js`,这个没有放入 `github action`中, 运行时间太长

## 涉及的环境

- python
- R

安装 python 以后,还需再命令行安装其他软件

```python
pip install -r requirements.txt
```

安装 R 以后, 还需要

```R
install.packages(c("stringr", "tibble","data.table", "purrr"))
```
