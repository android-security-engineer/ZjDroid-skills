import { defineConfig } from 'vitepress'

// 部署到 GitHub Pages: https://android-security-engineer.github.io/ZjDroid-skills/
// 因此 base 必须为仓库名（前后都带斜杠）
export default defineConfig({
  lang: 'zh-CN',
  title: 'ZjDroid',
  titleTemplate: 'ZjDroid · Android 动态逆向工具',
  description: '基于 Xposed 框架的 Android 应用动态逆向分析工具 —— 脱壳、内存 dump、API 监控、Lua 脚本注入的教学文档',
  base: '/ZjDroid-skills/',
  lastUpdated: true,
  cleanUrls: true,

  head: [
    ['meta', { name: 'theme-color', content: '#3c8772' }],
    ['meta', { name: 'author', content: 'ZjDroid' }]
  ],

  themeConfig: {
    nav: [
      { text: '介绍', link: '/intro/what-is-zjdroid' },
      { text: '快速开始', link: '/guide/getting-started' },
      { text: '功能原理', link: '/features/dex-dump' },
      { text: '命令参考', link: '/reference/commands' },
      {
        text: '源码',
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
