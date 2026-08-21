import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

import { describe, expect, it } from 'vitest'

const tokensCss = readFileSync(resolve('src/styles/tokens.css'), 'utf8')
const planCreatorCss = readFileSync(resolve('src/styles/plancreator.css'), 'utf8')

describe('PlanCreator exercise-slot role palette', () => {
  it('defines distinct dark and light role colors without reusing the app accent', () => {
    expect(tokensCss).toContain('--rolePrimary: #e85aad;')
    expect(tokensCss).toContain('--rolePrimary: #a92c74;')
    expect(tokensCss).toContain('--roleSecondary: #64a0e8;')
    expect(tokensCss).toContain('--roleSecondary: #2f6fa8;')
    expect(tokensCss).toContain('--roleVolume: #2bc28a;')
    expect(tokensCss).toContain('--roleVolume: #147a59;')
    expect(tokensCss).toContain('--roleAccessory: #9a84c8;')
    expect(tokensCss).toContain('--roleAccessory: #6f5aa0;')
    expect(tokensCss).not.toContain('--rolePrimary: #d0b487;')
    expect(tokensCss).not.toContain('--rolePrimary: #8f6f38;')
  })

  it('gives Primary the strongest rail and Secondary a restrained emphasis', () => {
    expect(planCreatorCss).toMatch(
      /\.slot-editor\.role-primary-progressive\s*{[^}]*--slot-role-border-strength: 40%;[^}]*--slot-role-rail-strength: 92%;[^}]*--slot-role-rail-width: 4px;/s,
    )
    expect(planCreatorCss).toMatch(
      /\.slot-editor\.role-secondary-progressive\s*{[^}]*--slot-role-border-strength: 34%;[^}]*--slot-role-rail-strength: 84%;/s,
    )
  })
})
