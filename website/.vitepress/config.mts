import { type DefaultTheme } from 'vitepress'
import { withMermaid } from 'vitepress-plugin-mermaid'
import { readdirSync, readFileSync, statSync, existsSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

// ─────────────────────────────────────────────────────────────────────────────
// 自动 sidebar 生成器
//
// 文档量已达数百篇，手工维护 sidebar 不现实。这里在「构建时」递归扫描指定目录，
// 依据每个 Markdown 文件的 frontmatter（title / order）或首个 H1 自动生成分组侧边栏。
//   - 目录 → 可折叠分组（分组标题取自该目录的 index.md 的 title）
//   - 文件 → 侧边栏条目（排序取 frontmatter.order，回退文件名）
// 新增文档只要放进对应目录、写好 frontmatter，就会自动出现在侧边栏，无需改本文件。
// ─────────────────────────────────────────────────────────────────────────────

const DOCS_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..')

interface Meta {
  title?: string
  order?: number
}

function parseMeta(absFile: string): Meta {
  const raw = readFileSync(absFile, 'utf-8')
  const meta: Meta = {}
  const fm = raw.match(/^---\r?\n([\s\S]*?)\r?\n---/)
  if (fm) {
    const t = fm[1].match(/^title:\s*(.+)$/m)
    if (t) meta.title = t[1].trim().replace(/^["']|["']$/g, '')
    const o = fm[1].match(/^order:\s*(-?\d+)/m)
    if (o) meta.order = parseInt(o[1], 10)
  }
  if (!meta.title) {
    const h1 = raw.match(/^#\s+(.+?)\s*$/m)
    if (h1) meta.title = h1[1].trim()
  }
  return meta
}

function dirMeta(absDir: string, fallback: string): Meta {
  const idx = join(absDir, 'index.md')
  if (existsSync(idx)) {
    const m = parseMeta(idx)
    return { title: m.title ?? fallback, order: m.order ?? 999 }
  }
  return { title: fallback, order: 999 }
}

function scanDir(absDir: string, urlBase: string): DefaultTheme.SidebarItem[] {
  const names = readdirSync(absDir)
  const dirs: string[] = []
  const files: { text: string; link: string; order: number; name: string }[] = []

  for (const name of names) {
    const abs = join(absDir, name)
    if (statSync(abs).isDirectory()) {
      dirs.push(name)
    } else if (name.endsWith('.md') && name !== 'index.md') {
      const m = parseMeta(abs)
      files.push({
        text: m.title ?? name.replace(/\.md$/, ''),
        link: `${urlBase}/${name.replace(/\.md$/, '')}`,
        order: m.order ?? 999,
        name
      })
    }
  }

  files.sort((a, b) => a.order - b.order || a.name.localeCompare(b.name))
  const fileItems: DefaultTheme.SidebarItem[] = files.map((f) => ({
    text: f.text,
    link: f.link
  }))

  const dirGroups = dirs
    .map((d) => {
      const abs = join(absDir, d)
      const meta = dirMeta(abs, d)
      const idxAbs = join(abs, 'index.md')
      const group: DefaultTheme.SidebarItem = {
        text: meta.title,
        collapsed: true,
        items: scanDir(abs, `${urlBase}/${d}`)
      }
      // 若目录含 index.md，则分组标题本身也可点击进入概览页
      if (existsSync(idxAbs)) group.link = `${urlBase}/${d}/`
      return { order: meta.order ?? 999, name: d, group }
    })
    .sort((a, b) => a.order - b.order || a.name.localeCompare(b.name))
    .map((x) => x.group)

  return [...fileItems, ...dirGroups]
}

function genSidebar(relDir: string): DefaultTheme.SidebarItem[] {
  const abs = join(DOCS_ROOT, relDir)
  if (!existsSync(abs)) return []
  return scanDir(abs, `/${relDir}`)
}

// ─────────────────────────────────────────────────────────────────────────────

// 部署到 GitHub Pages: https://android-security-engineer.github.io/ZjDroid-skills/
// 因此 base 必须为仓库名（前后都带斜杠）
// withMermaid 包裹后，Markdown 中的 ```mermaid 代码块会被渲染为图表。
export default withMermaid({
  lang: 'zh-CN',
  title: 'ZjDroid',
  titleTemplate: 'ZjDroid · Android 动态逆向工具',
  description:
    '基于 Xposed 框架的 Android 应用动态逆向分析工具 —— 脱壳、内存 dump、API 监控、Lua 脚本注入的教学文档',
  base: '/ZjDroid-skills/',
  lastUpdated: true,
  cleanUrls: true,
  ignoreDeadLinks: true,

  head: [
    ['meta', { name: 'theme-color', content: '#3c8772' }],
    ['meta', { name: 'author', content: 'ZjDroid' }]
  ],

  markdown: {
    // shiki 不内置 smali 语法，将其别名到 java 以获得基本着色，同时消除构建告警
    languageAlias: {
      smali: 'java'
    }
  },

  themeConfig: {
    nav: [
      { text: '介绍', link: '/intro/what-is-zjdroid' },
      { text: '快速开始', link: '/guide/getting-started' },
      { text: '功能原理', link: '/features/dex-dump' },
      {
        text: '深入源码',
        items: [
          { text: '架构与原理', link: '/architecture/overview' },
          { text: 'ZjDroid 源码精讲', link: '/source/' },
          { text: '内嵌工具链原理', link: '/internals/' }
        ]
      },
      { text: '命令参考', link: '/reference/commands' },
      {
        text: '源码仓库',
        link: 'https://github.com/android-security-engineer/ZjDroid-skills'
      }
    ],

    sidebar: {
      '/intro/': [
        {
          text: '项目介绍',
          items: [
            { text: 'ZjDroid 是什么', link: '/intro/what-is-zjdroid' },
            { text: '它解决什么问题', link: '/intro/problem-it-solves' },
            { text: '能力总览', link: '/intro/capabilities' },
            { text: '适用场景与局限', link: '/intro/limitations' }
          ]
        }
      ],
      '/guide/': [
        {
          text: '快速开始',
          items: [
            { text: '环境准备', link: '/guide/getting-started' },
            { text: '安装与启用模块', link: '/guide/install' },
            { text: '发送第一条指令', link: '/guide/first-command' },
            { text: '查看执行结果', link: '/guide/view-results' }
          ]
        },
        {
          text: '进阶',
          items: [
            { text: '工作流程总览', link: '/guide/workflow' },
            { text: 'ApkProtect 特殊处理', link: '/guide/apkprotect' }
          ]
        }
      ],
      '/features/': [
        {
          text: '功能实现原理',
          items: [
            { text: 'DEX 内存 Dump', link: '/features/dex-dump' },
            { text: '内存 BackSmali 脱壳', link: '/features/backsmali' },
            { text: 'DEX 加载信息收集', link: '/features/dexinfo' },
            { text: '类信息枚举', link: '/features/dump-class' },
            { text: '内存区域 Dump', link: '/features/mem-dump' },
            { text: 'Dalvik 堆 Dump', link: '/features/heap-dump' },
            { text: 'Lua 脚本注入', link: '/features/lua-invoke' },
            { text: '敏感 API 监控', link: '/features/api-monitor' }
          ]
        }
      ],
      '/architecture/': [
        { text: '架构与原理', link: '/architecture/overview', items: genSidebar('architecture') }
      ],
      '/source/': [
        { text: 'ZjDroid 源码精讲', link: '/source/', items: genSidebar('source') }
      ],
      '/internals/': [
        { text: '内嵌工具链原理', link: '/internals/', items: genSidebar('internals') }
      ],
      '/reference/': [
        {
          text: '命令参考',
          items: [
            { text: '命令总览', link: '/reference/commands' },
            { text: '指令协议', link: '/reference/protocol' }
          ]
        },
        {
          text: '附录',
          items: [
            { text: 'API 监控清单', link: '/reference/api-hooks' },
            { text: '目录结构', link: '/reference/structure' }
          ]
        }
      ]
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/android-security-engineer/ZjDroid-skills' }
    ],

    outline: {
      level: [2, 3],
      label: '本页内容'
    },

    docFooter: {
      prev: '上一页',
      next: '下一页'
    },

    lastUpdatedText: '最后更新',

    returnToTopLabel: '回到顶部',
    sidebarMenuLabel: '菜单',
    darkModeSwitchLabel: '外观',
    lightModeSwitchTitle: '切换到浅色模式',
    darkModeSwitchTitle: '切换到深色模式',

    search: {
      provider: 'local',
      options: {
        translations: {
          button: {
            buttonText: '搜索文档',
            buttonAriaLabel: '搜索文档'
          },
          modal: {
            noResultsText: '无法找到相关结果',
            resetButtonTitle: '清除查询条件',
            footer: {
              selectText: '选择',
              navigateText: '切换'
            }
          }
        }
      }
    },

    footer: {
      message: '基于 MIT 协议发布 · 本文档仅用于安全研究与教学目的',
      copyright: 'Copyright © ZjDroid'
    }
  }
})
