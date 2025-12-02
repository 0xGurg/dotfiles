return {
	'echasnovski/mini.snippets',
	version = '*',
	lazy = false, -- Load early so blink.cmp can use it
	config = function()
		local snippets = require('mini.snippets')
		snippets.setup({
			snippets = {
				-- =====================
				-- React Hooks
				-- =====================
				{ prefix = 'us', desc = 'useState', body = 'const [${1:state}, set${1/(.*)/${1:/capitalize}/}] = useState(${2:initial})' },
				{ prefix = 'ue', desc = 'useEffect', body = 'useEffect(() => {\n\t${0}\n}, [${1}])' },
				{ prefix = 'uec', desc = 'useEffect cleanup', body = 'useEffect(() => {\n\t${0}\n\n\treturn () => {\n\t\t${1:cleanup}\n\t}\n}, [${2}])' },
				{ prefix = 'ur', desc = 'useRef', body = 'const ${1:ref} = useRef(${2:null})' },
				{ prefix = 'um', desc = 'useMemo', body = 'const ${1:value} = useMemo(() => ${2:compute}, [${3:deps}])' },
				{ prefix = 'uc', desc = 'useCallback', body = 'const ${1:callback} = useCallback((${2:args}) => {\n\t${0}\n}, [${3:deps}])' },
				{ prefix = 'uctx', desc = 'useContext', body = 'const ${1:value} = useContext(${2:Context})' },

				-- =====================
				-- React Components
				-- =====================
				{ prefix = 'rfc', desc = 'React Function Component', body = 'export function ${1:Component}({ ${2:props} }) {\n\treturn (\n\t\t<div>\n\t\t\t${0}\n\t\t</div>\n\t)\n}' },
				{ prefix = 'rfce', desc = 'React FC export default', body = 'function ${1:Component}({ ${2:props} }) {\n\treturn (\n\t\t<div>\n\t\t\t${0}\n\t\t</div>\n\t)\n}\n\nexport default ${1:Component}' },
				{ prefix = 'rfcp', desc = 'React FC with Props type', body = 'type ${1:Component}Props = {\n\t${2:prop}: ${3:string}\n}\n\nexport function ${1:Component}({ ${2:prop} }: ${1:Component}Props) {\n\treturn (\n\t\t<div>\n\t\t\t${0}\n\t\t</div>\n\t)\n}' },

				-- =====================
				-- Console
				-- =====================
				{ prefix = 'cl', desc = 'console.log', body = 'console.log(${0})' },
				{ prefix = 'clv', desc = 'console.log variable', body = "console.log('${1:var}:', ${1:var})" },
				{ prefix = 'clj', desc = 'console.log JSON', body = "console.log(JSON.stringify(${1:obj}, null, 2))" },
				{ prefix = 'ce', desc = 'console.error', body = 'console.error(${0})' },
				{ prefix = 'cw', desc = 'console.warn', body = 'console.warn(${0})' },

				-- =====================
				-- Functions
				-- =====================
				{ prefix = 'af', desc = 'arrow function', body = 'const ${1:name} = (${2:args}) => {\n\t${0}\n}' },
				{ prefix = 'afr', desc = 'arrow function return', body = 'const ${1:name} = (${2:args}) => ${0}' },
				{ prefix = 'aaf', desc = 'async arrow function', body = 'const ${1:name} = async (${2:args}) => {\n\t${0}\n}' },
				{ prefix = 'fn', desc = 'function', body = 'function ${1:name}(${2:args}) {\n\t${0}\n}' },
				{ prefix = 'afn', desc = 'async function', body = 'async function ${1:name}(${2:args}) {\n\t${0}\n}' },

				-- =====================
				-- Import/Export
				-- =====================
				{ prefix = 'imp', desc = 'import', body = "import { ${2:module} } from '${1:package}'" },
				{ prefix = 'impd', desc = 'import default', body = "import ${2:module} from '${1:package}'" },
				{ prefix = 'impa', desc = 'import all', body = "import * as ${2:module} from '${1:package}'" },
				{ prefix = 'exp', desc = 'export', body = 'export { ${0} }' },
				{ prefix = 'expd', desc = 'export default', body = 'export default ${0}' },
				{ prefix = 'expf', desc = 'export function', body = 'export function ${1:name}(${2:args}) {\n\t${0}\n}' },
				{ prefix = 'expc', desc = 'export const', body = 'export const ${1:name} = ${0}' },

				-- =====================
				-- Async/Promise
				-- =====================
				{ prefix = 'tc', desc = 'try/catch', body = 'try {\n\t${0}\n} catch (error) {\n\tconsole.error(error)\n}' },
				{ prefix = 'tca', desc = 'try/catch async', body = 'try {\n\t${0}\n} catch (error) {\n\tconsole.error(error)\n} finally {\n\t${1}\n}' },
				{ prefix = 'prom', desc = 'new Promise', body = 'new Promise((resolve, reject) => {\n\t${0}\n})' },
				{ prefix = 'fetc', desc = 'fetch', body = "const response = await fetch('${1:url}')\nconst ${2:data} = await response.json()" },

				-- =====================
				-- TypeScript
				-- =====================
				{ prefix = 'int', desc = 'interface', body = 'interface ${1:Name} {\n\t${0}\n}' },
				{ prefix = 'type', desc = 'type alias', body = 'type ${1:Name} = ${0}' },
				{ prefix = 'typeo', desc = 'type object', body = 'type ${1:Name} = {\n\t${0}\n}' },

				-- =====================
				-- Conditionals
				-- =====================
				{ prefix = 'if', desc = 'if statement', body = 'if (${1:condition}) {\n\t${0}\n}' },
				{ prefix = 'ife', desc = 'if/else', body = 'if (${1:condition}) {\n\t${0}\n} else {\n\t${2}\n}' },
				{ prefix = 'ter', desc = 'ternary', body = '${1:condition} ? ${2:then} : ${3:else}' },

				-- =====================
				-- Loops
				-- =====================
				{ prefix = 'fori', desc = 'for index loop', body = 'for (let ${1:i} = 0; ${1:i} < ${2:length}; ${1:i}++) {\n\t${0}\n}' },
				{ prefix = 'forof', desc = 'for...of', body = 'for (const ${1:item} of ${2:array}) {\n\t${0}\n}' },
				{ prefix = 'forin', desc = 'for...in', body = 'for (const ${1:key} in ${2:object}) {\n\t${0}\n}' },

				-- =====================
				-- Array Methods
				-- =====================
				{ prefix = 'map', desc = '.map()', body = '.map((${1:item}) => ${0})' },
				{ prefix = 'filter', desc = '.filter()', body = '.filter((${1:item}) => ${0})' },
				{ prefix = 'find', desc = '.find()', body = '.find((${1:item}) => ${0})' },
				{ prefix = 'reduce', desc = '.reduce()', body = '.reduce((${1:acc}, ${2:item}) => ${0}, ${3:initial})' },
				{ prefix = 'foreach', desc = '.forEach()', body = '.forEach((${1:item}) => {\n\t${0}\n})' },

				-- =====================
				-- Testing
				-- =====================
				{ prefix = 'desc', desc = 'describe block', body = "describe('${1:description}', () => {\n\t${0}\n})" },
				{ prefix = 'it', desc = 'it block', body = "it('${1:description}', () => {\n\t${0}\n})" },
				{ prefix = 'ita', desc = 'it async', body = "it('${1:description}', async () => {\n\t${0}\n})" },
				{ prefix = 'exp', desc = 'expect', body = 'expect(${1:value}).${2:toBe}(${0})' },
			},
		})
	end
}
