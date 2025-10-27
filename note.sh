# ==============================================
# 极简笔记系统 (Note System) v1.1
# 作者: gall911 with DeepSeek-V3
# 描述: 命令行极简笔记工具，支持分类存储和智能搜索
# 创建时间: 2024
# ==============================================

# 极简笔记系统核心函数
note() {
    local VERSION="v1.1 by gall911 with DeepSeek-V3"
    local NOTE_DIR="$HOME/notes"

    # 检查笔记目录状态
    local dir_status=""
    if [ -d "$NOTE_DIR" ]; then
        if [ -n "$(ls -A "$NOTE_DIR" 2>/dev/null)" ]; then
            dir_status="✅ 目录已存在且包含笔记"
        else
            dir_status="📁 目录已存在但为空"
        fi
    else
        dir_status="🆕 目录不存在，将在首次使用时创建"
    fi

    if [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo "📘 极简笔记系统 $VERSION"
        echo "主要开发: gall911"
        echo "AI技术支持: DeepSeek-V3"
        echo ""
        echo "📁 文件存储说明:"
        echo "  - 笔记目录: $NOTE_DIR/"
        echo "  - 每个分类保存在独立文件: $NOTE_DIR/<分类>.txt"
        echo "  - 当前状态: $dir_status"
        echo ""
        echo "用法:"
        echo "  note add <分类> <命令> <说明>    # 添加笔记"
        echo "  note <分类> [关键词]            # 搜索笔记"
        echo "  note list                       # 显示所有分类"
        echo "  note status                     # 显示系统状态"
        echo "  note version                    # 显示版本"
        echo "  note help                       # 显示此帮助"
        echo ""
        echo "示例:"
        echo "  note add vim dd \"删除当前行\""
        echo "  note vim 删除"
        echo "  note vim"
        return 0
    fi

    if [ "$1" = "version" ] || [ "$1" = "-v" ] || [ "$1" = "--version" ]; then
        echo "📘 极简笔记系统 $VERSION"
        echo ""
        echo "📁 文件存储:"
        echo "  笔记目录: $NOTE_DIR/"
        echo "  当前状态: $dir_status"
        return 0
    fi

    if [ "$1" = "status" ]; then
        echo "📊 笔记系统状态"
        echo "────────────────────────────────────"
        echo "版本: $VERSION"
        echo "笔记目录: $NOTE_DIR"
        echo "目录状态: $dir_status"

        if [ -d "$NOTE_DIR" ] && [ -n "$(ls -A "$NOTE_DIR" 2>/dev/null)" ]; then
            echo ""
            echo "📂 现有分类:"
            ls $NOTE_DIR/*.txt 2>/dev/null | sed 's|.*/||;s|\.txt||' | while read category; do
                count=$(grep -c "^cmd:" $NOTE_DIR/"$category".txt 2>/dev/null || echo 0)
                size=$(du -h $NOTE_DIR/"$category".txt 2>/dev/null | cut -f1)
                echo "  📖 $category: $count 条笔记 ($size)"
            done
        fi
        return 0
    fi

    if [ "$1" = "list" ]; then
        if [ ! -d "$NOTE_DIR" ] || [ -z "$(ls -A "$NOTE_DIR" 2>/dev/null)" ]; then
            echo "📭 笔记目录为空"
            echo "使用 'note add <分类> <命令> <说明>' 添加第一条笔记"
            return 0
        fi

        echo "📁 可用分类 (存储在 $NOTE_DIR/):"
        ls $NOTE_DIR/*.txt 2>/dev/null | sed 's|.*/||;s|\.txt||' | while read category; do
            count=$(grep -c "^cmd:" $NOTE_DIR/"$category".txt 2>/dev/null || echo 0)
            echo "  📂 $category ($count 条笔记)"
        done
        return 0
    fi

    if [ "$1" = "add" ]; then
        if [ $# -lt 4 ]; then
            echo "❌ 参数不足！用法: note add <分类> <命令> <说明>"
            return 1
        fi
        category="$2"
        command="$3"
        description="$4"

        # 创建目录（如果不存在）
        if [ ! -d "$NOTE_DIR" ]; then
            mkdir -p "$NOTE_DIR"
            echo "📁 已创建笔记目录: $NOTE_DIR/"
        fi

        # 检查是否首次添加该分类
        local first_entry=""
        if [ ! -f $NOTE_DIR/"$category".txt ]; then
            first_entry="🆕 新分类"
        fi

        echo "# $command" >> $NOTE_DIR/"$category".txt
        echo "cmd: $command" >> $NOTE_DIR/"$category".txt
        echo "desc: $description" >> $NOTE_DIR/"$category".txt
        echo "" >> $NOTE_DIR/"$category".txt

        echo "✅ 已添加到 $category: $command $first_entry"
        echo "📁 存储位置: $NOTE_DIR/$category.txt"
        return 0
    fi

    category="$1"
    keyword="$2"

    # 检查分类是否存在
    if [ ! -f $NOTE_DIR/"$category".txt ]; then
        echo "❌ 分类不存在: $category"
        echo "📁 可用分类 (存储在 $NOTE_DIR/):"
        if [ -d "$NOTE_DIR" ] && [ -n "$(ls -A "$NOTE_DIR" 2>/dev/null)" ]; then
            ls $NOTE_DIR/*.txt 2>/dev/null | sed 's|.*/||;s|\.txt||' | while read cat; do
                count=$(grep -c "^cmd:" $NOTE_DIR/"$cat".txt 2>/dev/null || echo 0)
                echo "  📂 $cat ($count 条笔记)"
            done
        else
            echo "  📭 暂无分类，使用 'note add' 添加第一条笔记"
        fi
        return 1
    fi

    if [ -n "$keyword" ]; then
        echo "🔍 在 $category 中搜索: \"$keyword\""
        echo "────────────────────────────────────"
        awk -v search="$keyword" 'BEGIN { IGNORECASE=1; found=0; entry=""; count=0 } /^#/ { if (found && entry != "") { print entry; print "────────────────────────────────────"; count++; } entry=$0; found=0 } /^cmd:|^desc:/ { entry=entry "\n" $0; if ($0 ~ search) found=1; } /^$/ { if (found && entry != "") { print entry; print "────────────────────────────────────"; count++; found=0; } entry=""; } END { if (found && entry != "") { print entry; print "────────────────────────────────────"; count++; } if (count == 0) { print "❌ 未找到匹配的笔记" } else { print "📊 找到 " count " 条结果" } }' $NOTE_DIR/"$category".txt
    else
        local count=$(grep -c "^cmd:" $NOTE_DIR/"$category".txt)
        echo "📁 $category 分类 ($count 条笔记)"
        echo "────────────────────────────────────"
        cat $NOTE_DIR/"$category".txt
        echo "────────────────────────────────────"
        echo "📊 共 $count 条笔记"
        echo "📁 文件位置: $NOTE_DIR/$category.txt"
    fi
}
# 设置短别名
alias n=note

#=========  n  专用补全 =========
# note 命令的自动补全功能
_note_completion() {
    local cur prev notes_dir
    notes_dir="$HOME/notes"

    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # 第一级补全：子命令和分类
    if [ $COMP_CWORD -eq 1 ]; then
        local subcommands="add list help version status del"
        local categories=""

        # 获取已有的分类
        if [ -d "$notes_dir" ]; then
            categories=$(ls "$notes_dir"/*.txt 2>/dev/null | xargs -I {} basename {} .txt)
        fi

        COMPREPLY=( $(compgen -W "$subcommands $categories" -- "$cur") )

    # 第二级补全：add 命令后的分类补全
    elif [ $COMP_CWORD -eq 2 ] && [ "${prev}" = "add" ]; then
        # 这里可以预定义一些常用分类，或者留空让用户自己输入
        local common_categories="linux mud git vim project note"
        COMPREPLY=( $(compgen -W "$common_categories" -- "$cur") )

    # 第二级补全：del 命令后的分类补全
    elif [ $COMP_CWORD -eq 2 ] && [ "${prev}" = "del" ]; then
        local categories=""
        if [ -d "$notes_dir" ]; then
            categories=$(ls "$notes_dir"/*.txt 2>/dev/null | xargs -I {} basename {} .txt)
        fi
        COMPREPLY=( $(compgen -W "$categories" -- "$cur") )

    # 第三级补全：del 分类后的命令补全
    elif [ $COMP_CWORD -eq 3 ] && [ "${COMP_WORDS[1]}" = "del" ]; then
        local category="${COMP_WORDS[2]}"
        local commands=""
        if [ -f "$notes_dir/$category.txt" ]; then
            # 提取该分类下的所有命令关键词
            commands=$(grep "^# " "$notes_dir/$category.txt" | cut -d' ' -f2-)
        fi
        COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
    fi
}

# 注册自动补全
complete -F _note_completion note
complete -F _note_completion n  # 为别名也注册补全
