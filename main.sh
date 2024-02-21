#!/bin/bash

git config user.name zoushucai
git config user.email 1228075512@qq.com

check_submodule() {
    # 获取子模块列表
    git submodule update --remote
    submodules=$(git submodule | awk '{print $2}')

    # 遍历每个子模块
    is_need_update=0
    for submodule in $submodules; do
        # 获取子模块的当前版本号
        local_version=$(git submodule status $submodule | awk '{print $1}')
        # 获取子模块的远程版本号
        remote_version=$(git ls-remote $(git config -f .gitmodules --get submodule.$submodule.url) HEAD | cut -f1)

        # 检查本地版本号和远程版本号是否一致
        if [ "$local_version" != "$remote_version" ]; then
            echo "Updating submodule: $submodule"
            # 更新子模块
            git submodule update --remote $submodule
            # 提交子模块更新
            git add $submodule
            git commit -m "Update submodule $submodule to latest version"
            echo "Submodule $submodule updated to the latest version."
            is_need_update=1
        else
            echo "Submodule $submodule is up-to-date. No action needed."
        fi
    done

    if [ $is_need_update -eq 0 ]; then
        echo "No submodule need to update."
        exit 0
    fi
}

# 函数：下载并拷贝文件
download_and_copy_files() {
    echo "------- 判断是否需要下载 woodward_library.csv 文件 ----------"
    python ./down_woodward.py
    sleep 5
    python ./copyfile.py
}

# 函数：提交更新
commit_and_push_updates() {
    echo "--------------- 判断是否需要更新仓库 -------------------------------"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    AA_DIR="$SCRIPT_DIR"

    process_directory() {
        local dir=$1
        cd "$dir" || exit 1
        echo "---------------------------------------------------------------------------"
        echo "Current directory: $(pwd)"
        
        if [ -z "$(git status --porcelain)" ]; then
            echo "No changes to commit."
        else
            git pull origin main
            sleep 10
            git add .
            git commit -m "Update by bash"
            if git show-ref --quiet refs/heads/dev; then
                echo "Branch 'dev' exists."
                git checkout dev 
                git checkout main
            else
                echo "Branch 'dev' does not exist."
                git checkout -b dev 
                git checkout main
            fi
            sleep 10
            git push origin main
            echo "Done."
        fi
    }

    process_directory "$AA_DIR"
}


check_submodule
download_and_copy_files
commit_and_push_updates



