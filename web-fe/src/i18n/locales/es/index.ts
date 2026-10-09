import analysis from './analysis'
import atlas from './atlas'
import common from './common'
import execution from './execution'
import home from './home'
import plans from './plans'

export default { ...common, ...atlas, ...plans, ...analysis, ...execution, ...home }
