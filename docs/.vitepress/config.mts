import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Devastation',
  description: 'Local-first developer environment runbook',
  cleanUrls: true,
  themeConfig: {
    nav: [
      { text: 'Start', link: '/' },
      { text: 'GitLab', link: '/gitlab-runner' },
      { text: 'Vault', link: '/vault' },
      { text: 'Services', link: '/services' },
      { text: 'TeamCity', link: '/teamcity' }
    ],
    sidebar: [
      {
        text: 'Runbooks',
        items: [
          { text: 'Overview', link: '/' },
          { text: 'GitLab And Runner', link: '/gitlab-runner' },
          { text: 'Vault', link: '/vault' },
          { text: 'SNS, SQS, And S3', link: '/services' },
          { text: 'TeamCity', link: '/teamcity' }
        ]
      }
    ]
  }
})
