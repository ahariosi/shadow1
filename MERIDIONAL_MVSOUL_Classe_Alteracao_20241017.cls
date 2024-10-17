Class shift.bo.ConverteObj Extends Ens.BusinessOperation [ ProcedureBlock ]
{

Parameter ADAPTER;

Parameter INVOCATION = "Queue";

Property Homologacao As %Boolean;

Parameter SETTINGS = "Homologacao";

Method ConverteObjShift(pRequest As shift.msg.ConverteObjShiftRequest, pResponse As shift.msg.ConverteObjShiftResponse) As %Status
{
    Try
    {
        Set Status = $$$OK
        Set pResponse = ##class(shift.msg.ConverteObjShiftResponse).%New()        

        Set objIntegracao = ##class(dado.shifthis.mv.TblIntegracao).%OpenId(pRequest.IdIntegracao,,.Status)
        If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)        

        Set pResponse.IDMensagemRequest = pRequest.%Id()
        Set pedidoLab = ##class(shift.xml.lis.imp.PedidoLab).%New()
        Do pedidoLab.PedidoNewObject()
        Set pedidoLab.UsuarioWebId = pRequest.PedidoMV.Cabecalho.IdentificacaoCliente
        Set pedidoLab.Identificador = pRequest.PedidoMV.Cabecalho.IdentificacaoCliente
        Set pedidoLab.Pedido.Observacao = pRequest.PedidoMV.PedidoExame.Observacao

        If (objIntegracao.DeParaSetor) //Aba Importacao - Flag De/Para Unidade de Coleta
        {
	        Set posto = pRequest.PedidoMV.PedidoExame.SetorSolicitante
        }
        Else
        {
	        Set posto = pRequest.PedidoMV.PedidoExame.Exames.Exame.GetAt(1).Coleta.Posto
        }
        
        If (objIntegracao.ConcatenarPosto && (pRequest.PedidoMV.PedidoExame.CodigoEmpresaPedido '= ""))
        {
        	Set pedidoLab.Pedido.Posto = posto_"*"_pRequest.PedidoMV.PedidoExame.CodigoEmpresaPedido
        }
        Else
        {
	        Set pedidoLab.Pedido.Posto = posto
        }
        
        Set pedidoLab.Pedido.Convenio = pRequest.PedidoMV.PedidoExame.Convenio
        Set pedidoLab.Pedido.Codigo = pRequest.PedidoMV.PedidoExame.Atendimento.CodigoAtendimento_"*"_pRequest.PedidoMV.PedidoExame.CodigoPedido
        Set pedidoLab.Pedido.OrdemServico = pRequest.PedidoMV.PedidoExame.Atendimento.CodigoAtendimento_"*"_pRequest.PedidoMV.PedidoExame.CodigoPedido
        Set pedidoLab.Pedido.Leito = pRequest.PedidoMV.PedidoExame.Atendimento.DescLeito
        
        Set objColetaProgramada = ##class(shift.xml.lis.imp.ColetaProgramada).%New()
        If (pRequest.PedidoMV.PedidoExame.DataColetaPedido '= "")
        {        	
        	Set objColetaProgramada.DataProgramada = $PIECE(pRequest.PedidoMV.PedidoExame.DataColetaPedido," ",1)
        	Set objColetaProgramada.HoraProgramada = $EXTRACT($PIECE(pRequest.PedidoMV.PedidoExame.DataColetaPedido," ",2),1,8)
        }
        
        If (objIntegracao.DeParaDadoCadastral)
        {
	        If ((objIntegracao.ConvenioUnico) && (objIntegracao.CodConvenioUnico '= ""))
	        {
	        	Set convenio = objIntegracao.CodConvenioUnico
	        }
	        Else
	        {
		        Set objDeParaConvenio = ##class(dado.shifthis.mv.TblDeParaConvenio).IdxClienteOpen(pRequest.IdIntegracao,pedidoLab.Pedido.Convenio)
		        If '$ISOBJECT(objDeParaConvenio)
		        {
			        Set convenio = pedidoLab.Pedido.Convenio
			    }
			    Else
			    {
			    	Set convenio = objDeParaConvenio.ConvenioApoio
			    }
	        }
	        
	        Set sql = "SELECT * FROM dado_shifthis_mv.TblDeParaDadoCadastral WHERE Integracao = ? And CodConvenioApoio = ?"
    		Set tStatement = ##class(%SQL.Statement).%New()
			Set Status = tStatement.%Prepare(sql)
			If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
			
			Set rset = tStatement.%Execute(pRequest.IdIntegracao,convenio)
			While rset.%Next()
			{
				Set objDado = ##class(shift.xml.lis.imp.DadoCadastral).%New()
				Set objDado.Codigo = rset.CodDadoApoio
				Set insereDado = 0
			
				If ((rset.CodDadoApoio = 1) & (pRequest.PedidoMV.PedidoExame.Paciente.Carteira '= ""))
				{
					Set objDado.Valor = pRequest.PedidoMV.PedidoExame.Paciente.Carteira
					Set insereDado = 1
				}
				ElseIf ((rset.CodDadoApoio = 2) & (pRequest.PedidoMV.PedidoExame.Paciente.DataValidadeCarteira '= ""))
				{
					Set objDado.Valor = pRequest.PedidoMV.PedidoExame.Paciente.DataValidadeCarteira
					Set insereDado = 1
				}
				ElseIf ((rset.CodDadoApoio = 3) & (pRequest.PedidoMV.PedidoExame.Guia '= ""))
				{
					Set objDado.Valor = pRequest.PedidoMV.PedidoExame.Guia
					Set insereDado = 1
				}
				ElseIf ((rset.CodDadoApoio = 4) & (pRequest.PedidoMV.PedidoExame.DataValidadeGuia '= ""))
				{
					Set objDado.Valor = pRequest.PedidoMV.PedidoExame.DataValidadeGuia
					Set insereDado = 1
				}
				ElseIf ((rset.CodDadoApoio = 5) & (pRequest.PedidoMV.PedidoExame.Senha '= ""))
				{
					Set objDado.Valor = pRequest.PedidoMV.PedidoExame.Senha
					Set insereDado = 1
				}
				ElseIf (rset.CodDadoApoio = 6)
				{
					Set objDado.Valor = rset.ValorDadoFixo
					Set insereDado = 1
				}
				ElseIf (rset.CodDadoApoio = 8)
				{
					Set objDado.Valor = pRequest.PedidoMV.PedidoExame.Convenio
					Set insereDado = 1
				}
				
				If (insereDado = 1)
				{
					Set Status = pedidoLab.Pedido.DadoCadastral.Insert(objDado)
					If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
				}
			}
        }
		
        Do pedidoLab.PacienteNewObject()
        Set pedidoLab.Paciente.Nome = pRequest.PedidoMV.PedidoExame.Paciente.Nome
        Set pedidoLab.Paciente.Codigo = pRequest.PedidoMV.PedidoExame.Paciente.CodigoPaciente
        If (pRequest.PedidoMV.PedidoExame.Paciente.Sexo = "G") 
        { 
        	Set sexo = "N"
        }
        Else 
        {
	        Set sexo = pRequest.PedidoMV.PedidoExame.Paciente.Sexo
        }
        Set pedidoLab.Paciente.Sexo = sexo
        Set pedidoLab.Paciente.DtNascimento = pRequest.PedidoMV.PedidoExame.Paciente.DataNascimento
		Set pedidoLab.Paciente.Cpf = pRequest.PedidoMV.PedidoExame.Paciente.NumeroCpf
        #DIM exameMV As shift.xml.mv.pdo.InfoExame
        Set qtdExamesMv = pRequest.PedidoMV.PedidoExame.Exames.Exame.Count()
        Set urgencia = $LISTFROMSTRING("U,E")
        For i=1:1:qtdExamesMv
        {
            Set exameMV = pRequest.PedidoMV.PedidoExame.Exames.Exame.GetAt(i)
            Set exame = ##class(shift.xml.lis.imp.Exame).%New()
            Set exame.Codigo = exameMV.CodigoExame
            Set exame.Observacao = exameMV.Observacao
			Set exame.Urgente = 0
			If ($LF(urgencia,pRequest.PedidoMV.PedidoExame.TipoSolicitacao))
			{
				Set exame.Urgente = 1
			}			
			Set exame.DescricaoMaterial = exameMV.Coleta.DescricaoMaterial
            If (objIntegracao.ConcatenarMaterial)
            {
	            Set exame.DescricaoMaterial = exameMV.Coleta.CodigoMaterial_" | "_exameMV.Coleta.DescricaoMaterial
            }
	        Set amostraEx = ##class(shift.xml.lis.imp.Amostra).%New()
    	    Set amostraEx.Cbarra = exameMV.Coleta.Amostra
            Set amostraEx.Tipo = exameMV.Coleta.Tubo
	        Set Status = exame.Amostras.Insert(amostraEx)
			
			Set DataHoraColeta = exameMV.Coleta.DataColetaPedido_" "_exameMV.Coleta.HoraColetaPedido
			
			Set objColetaProgramada = ##class(shift.xml.lis.imp.ColetaProgramada).%New()
	        If (DataHoraColeta '= "")
	        {
	        	Set objColetaProgramada.DataProgramada = $PIECE(DataHoraColeta," ",1)
	        	Set objColetaProgramada.HoraProgramada = $EXTRACT($PIECE(DataHoraColeta," ",2),1,8)
	        }	   
			
            If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
            Set medicoEx = ##class(shift.xml.lis.imp.MedicoExame).%New()
			If pRequest.PedidoMV.PedidoExame.TipoConselhoSolicitante '= "OUTROS"
			{
	            Set medicoEx.Nome = pRequest.PedidoMV.PedidoExame.DescPrestadorSolicitante
	            Set medicoEx.Crm = pRequest.PedidoMV.PedidoExame.NumeroConselhoSolicitante
	            Set medicoEx.Uf = $PIECE(pRequest.PedidoMV.PedidoExame.TipoConselhoSolicitante,"-",2)
	            Set medicoEx.Conselho = $PIECE(pRequest.PedidoMV.PedidoExame.TipoConselhoSolicitante,"-",1)
	            
	            If (medicoEx.Uf = "")
	            {
		            Set medicoEx.Uf = pRequest.PedidoMV.PedidoExame.UfConselhoSolicitante
	            }
			}
			Else
			{
				Set medicoEx.Nome = pRequest.PedidoMV.PedidoExame.DescPrestadorSolicitante
				Set medicoEx.Crm = "SEM.SOLICITACAO"
				Set medicoEx.Uf = pRequest.PedidoMV.PedidoExame.UfConselhoSolicitante
	            Set medicoEx.Conselho = pRequest.PedidoMV.PedidoExame.TipoConselhoSolicitante
			}
            Set Status = exame.Medico.Insert(medicoEx)
            If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
            
            If $ISOBJECT(objColetaProgramada)
            {
	            If (objColetaProgramada.DataProgramada '= "")
	            {
	            	Set exame.ColetaProgramada = objColetaProgramada
	            }
            }
            
            Set cobertura = $TRANSLATE(exameMV.Cobertura,"ÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÇáéíóúàèìòùãõâêîôûç","AEIOUAEIOUAOAEIOUCaeiouaeiouaoaeiouc")
			
			If ((cobertura '= "") && ((cobertura = "Autorizado por guia") || (cobertura = "Nao Autorizado")))
			{
				Set objIPAProc = ##class(shift.xml.lis.imp.InformacaoPreAnalitica).%New()
				Set objIPAProc.ValorId = "11"
			 	Set objIPAProc.Tipo = "P"
			 	Set objIPAProc.Valor = exameMV.Cobertura
			 	Do exame.InformacoesPreAnaliticas.Insert(objIPAProc)
			}
            
            Set Status = pedidoLab.Exame.Insert(exame)
            If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
        }
        //caso não tenha exames no pedido.
        If (pedidoLab.Exame.Count() < 1)
        {
            Set Status = $$$ERROR(5001,"Não foram enviados exames no pedido "_pRequest.PedidoMV.PedidoExame.CodigoPedido)
            Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
        }
        Set pResponse.PedidoShift = pedidoLab
    }
    Catch objErro
    {
        Set Status = ##class(shift.utl.TrataExcecao).Excecao(objErro)
        Set mensagemErro = $System.Status.GetOneErrorText(Status)
        Set pResponse.Retorno = 0
        Set pResponse.DescricaoErro = mensagemErro
        $$$LOGWARNING(mensagemErro)
    }
    Quit $$$OK
}

Method ConverteResultadoNormal(pRequest As shift.msg.ConverteResNormalRequest, Output pResponse As shift.msg.ConverteResNormalResponse) As %Status
{
    Try
    {			
        Set Status = $$$OK
        Set cControleErro = 0
        Set msgErro = ""
        Set msgErroGeral = ""   
        Set pResponse = ##class(shift.msg.ConverteResNormalResponse).%New()
      	
      	Set objIntegracao = ##class(dado.shifthis.mv.TblIntegracao).%OpenId(pRequest.IdIntegracao,,.Status)                
        If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
        
        Set oControlePedido = ##class(dado.shifthis.mv.TblControlePedido).%OpenId(pRequest.IdControlePedido,,.Status)                
        If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
        
        Set sql = 	"SELECT "_
        				"CodigoItemPedido, "_
        				"DescExame, "_
        				"Material, "_
        				"DescricaoMaterial, "_
        				"DeParaExame->CodExameApoio, "_
        				"Tipo, "_
        				"Situacao "_
        			"FROM "_
        				"dado_shifthis_mv.TblControleExame "_
        			"WHERE "_
        				"ControlePedido = ? "_
        				"AND (CodExameCliente = ? OR DeParaExame->CodExameCliente = ?)"
        				
        Set tStatement = ##class(%SQL.Statement).%New()
        Set Status = tStatement.%Prepare(sql)
        If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
        
        Set rset = tStatement.%Execute(pRequest.IdControlePedido,pRequest.ResultadoCliente.Exame.GetAt(1).Codigo,pRequest.ResultadoCliente.Exame.GetAt(1).Codigo)        
        If rset.%Next()
        {
            Set oMensagem = ##class(shift.xml.mv.cma.Mensagem).%New()
            Set oCabecalho = ##class(shift.xml.mv.cma.Cabecalho).%New()
            Set oCabecalho.mensagemID = oControlePedido.MensagemID
	        Set oCabecalho.versaoXML = $Case(oControlePedido.VersaoXML,"":1,:$ZStrip(oControlePedido.VersaoXML,"*C"))
	        Set oCabecalho.identificacaoCliente = oControlePedido.IdentificacaoCliente
	        Set oCabecalho.servico = "RESULTADO_EXAME"
	        Set oCabecalho.dataHora = $ZDateTime($Horolog,3)
	        Set oCabecalho.empresaOrigem = objIntegracao.EmpresaOrigem        
	        Set oCabecalho.sistemaOrigem = objIntegracao.SistemaOrigem
	        Set oCabecalho.empresaDestino = objIntegracao.EmpresaDestino
	        Set oCabecalho.sistemaDestino = objIntegracao.SistemaDestino
	        Set oCabecalho.usuario = objIntegracao.UsuarioMV
	        Set oCabecalho.senha = objIntegracao.SenhaMV
	        Set oMensagem.Cabecalho = oCabecalho
	        Set oResultado = ##class(shift.xml.mv.cma.Resultado).%New()

			Set exameExportado = ..ExameExportado(pRequest.IdIntegracao,pRequest.ResultadoCliente.Pedido.OrdemServico,pRequest.ResultadoCliente.Exame.GetAt(1).Codigo)
			If exameExportado
			{
				Set oResultado.operacao = "A"
			}
			Else
			{
				Set oResultado.operacao = "I"
			}
	        
	        Set oResultado.codigoPaciente = oControlePedido.CodigoPaciente
	        Set oResultado.codigoPacienteDePara = "" 
	        Set oResultado.nome = pRequest.ResultadoCliente.Paciente.Nome
	        Set oSolicitacao = ##class(shift.xml.mv.cma.solicitacao).%New()
	        Set oAtendimento = ##class(shift.xml.mv.cma.atendimento).%New()
	        Set oAtendimento.codigoAtendimento = oControlePedido.CodigoAtendimento
	        Set oAtendimento.codigoAtendimentoDePara = ""
	        Set oAtendimento.codigoConvenio = $PIECE(pRequest.ResultadoCliente.Pedido.Convenio,"*",1)
        	Set oSolicitacao.atendimento = oAtendimento
        	Set oPedido = ##class(shift.xml.mv.cma.pedido).%New()
	        Set oPedido.codigoPedido = $Piece(pRequest.ResultadoCliente.Pedido.OrdemServico,"*",2)
	        Set oPedido.codigoPedidoDePara = pRequest.ResultadoCliente.Pedido.OrdemServicoApoio
	        Set oPedido.codigoLaboratorio = "1"
	        Set oPedido.codigoLaboratorioDePara = ""
	        Set oPedido.prestadorSolicitante = oControlePedido.PrestadorSolicitante
	        Set oPedido.prestadorSolicitanteDePara = ""
	        Set oPedido.setorSolicitante = $PIECE(oControlePedido.PostoCliente,"*",1)
	        Set oPedido.setorSolicitanteDePara = oControlePedido.PostoApoio
	        Set oPedido.observacao = pRequest.ResultadoCliente.Exame.GetAt(1).Observacao
	        Set oSolicitacao.pedido = oPedido
	        Set oResultado.solicitacao = oSolicitacao
	        Set oExame = ##class(shift.xml.mv.cma.Exame).%New()
	        Set oExame.codigoItemPedido = rset.CodigoItemPedido
	        Set oExame.codigoItemPedidoDePara = ""
	        Set oExame.codigoExame = pRequest.ResultadoCliente.Exame.GetAt(1).Codigo
        	Set oExame.codigoExameDePara = rset.CodExameApoio
        	Set oExame.descExame = rset.DescExame
        	Set oExame.mnemonico = pRequest.ResultadoCliente.Exame.GetAt(1).Mnemonico
        	Set oExame.codigoMaterial = $Case(rset.Material,"":1,:$ZStrip(rset.Material,"*C"))
        	Set oExame.codigoMaterialDePara = ""
        	Set oExame.descMaterial = rset.DescricaoMaterial
        	Set oExame.observacao = pRequest.ResultadoCliente.Exame.GetAt(1).Observacao
        	
        	If exameExportado
        	{
	        	Set oExame.retificado = "S"
        	}
        		
        	If (objIntegracao.ExportaUsuariosDadosMV)
        	{
	        	Set Status = ..PreparaDadosOperadorMVNormal(objIntegracao, pRequest.ResultadoCliente.Exame.GetAt(1), .oExame)
        	}
        	Else
        	{
	        	Set oLogRequest = ##class(shift.msg.RecuperaInformacaoLogRequest).%New()
	        	Set oLogRequest.pExame = rset.CodExameApoio
	        	Set oLogRequest.pOs = pRequest.ResultadoCliente.Pedido.OrdemServicoApoio
	        	Set oLogRequest.Integracao = objIntegracao.Nome
	        	
	        	#Dim oLogdResponse As shift.msg.RecuperaInformacaoLogResponse
	        	Set Status = ..SendRequestSync("Shift_Customizacao", oLogRequest,.oLogdResponse)        	
	        	If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
	        	
	        	If ($ISOBJECT(oLogdResponse.RecuperaInformacaoLogResult))
	        	{
					If oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("011") '= ""
		        	{
		        		Set oExame.operadorCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("011").Operador
		    			Set oExame.dataHoraCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("011").DataHora
		        	}
		        	ElseIf oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("031") '= ""
		        	{
			        	Set oExame.operadorCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("031").Operador
				        Set oExame.dataHoraCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("031").DataHora
		        	}
		        	ElseIf oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("054") '= ""
		        	{
			        	Set oExame.operadorCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("054").Operador
				        Set oExame.dataHoraCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("054").DataHora
		        	}
		        	ElseIf oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("319") '= ""
		        	{
			        	Set oExame.operadorCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("319").Operador
				        Set oExame.dataHoraCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("319").DataHora				        
		        	}
		        	ElseIf oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("090") '= ""
		        	{
			        	Set oExame.operadorCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("090").Operador
				        Set oExame.dataHoraCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("090").DataHora
		        	}
		        	ElseIf oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("089") '= ""
		        	{
			        	Set oExame.operadorCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("089").Operador
				        Set oExame.dataHoraCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("089").DataHora
		        	}
		        	ElseIf oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("160") '= ""
		        	{
			        	Set oExame.operadorCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("160").Operador
				        Set oExame.dataHoraCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("160").DataHora
		        	}
		        	ElseIf oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("100") '= ""
		        	{
			        	Set oExame.operadorCadastro = "MV - MV"
				        Set oExame.dataHoraCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("100").DataHora
		        	}
		        	
		        	If oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("048") '= ""
		        	{
		        		Set oExame.operadorRevisao = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("048").Operador
		        		Set oExame.dataHoraRevisao = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("048").DataHora
		        	}
		        	ElseIf oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("013")'= "" 
		        	{
			        	Set oExame.operadorRevisao = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("013").Operador
				        Set oExame.dataHoraRevisao = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("013").DataHora
		        	}
		        	ElseIf oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("051")'= "" 
		        	{
			        	Set oExame.operadorRevisao = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("051").Operador
				        Set oExame.dataHoraRevisao = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("051").DataHora
		        	}
		        	
		        	If oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("013") '="" 
		        	{  
			        	Set oExame.operadorAssinatura = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("013").Operador
				        Set oExame.dataHoraAssinatura = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("013").DataHora
		        	} 
		        	ElseIf oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("051") 
		        	{
			        	Set oExame.operadorAssinatura = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("051").Operador
				        Set oExame.dataHoraAssinatura = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("051").DataHora
			        }
			        
			        If oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("025") '= "" 
			        {
			        	Set oExame.operadorLiberacao = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("025").Operador
			        	Set oExame.dataHoraLiberacao = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("025").DataHora
			        }
			        ElseIf oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("320") '= "" 
			        {
			        	Set oExame.operadorLiberacao = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("320").Operador
			        	Set oExame.dataHoraLiberacao = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("320").DataHora
			        }
			        Else
			        {
				        Set oExame.operadorLiberacao = oExame.operadorAssinatura
			        	Set oExame.dataHoraLiberacao = oExame.dataHoraAssinatura
			        }
	        	}
        	}

        	Set qtdCampo = pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.Count()

			For cCam=1:1:qtdCampo
        	{
	        	Set valorExame = pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.GetAt(cCam).Valor
	        	
	        	Set alteraSequencia = 0
	        	If $PIECE($NAMESPACE,"_",1) = "MATERDEI"  If $LENGTH(valorExame) > 300 Set alteraSequencia = 1
	        	
	        	Set qtdBlocosResExame = 0 

	        	While (valorExame '= "")
	        	{
	        		If ($Find(pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.GetAt(cCam).Apelido,"*") > 0 && alteraSequencia ) 
	        		{
		        		Set qtdBlocosResExame = qtdBlocosResExame + 1
		        		Set campoMV = $PIECE(pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.GetAt(cCam).Apelido,"*",1)_"*"_qtdBlocosResExame
	        		}
	        		Else
	        		{
		        		Set campoMV = pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.GetAt(cCam).Apelido
	        		}
		        	
		        	Set oValor = ##class(shift.xml.mv.cma.Valor).%New()
					If $Piece(campoMV,"*",2) = "" 
					{
						Set Status = $System.Status.Error(5001,"De/Para de máscara com formato inválido. Formato válido: <versao>*<ordem>.")
	            		Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
					}
		        	Set oValor.versao = $Piece(campoMV,"*",1)
		        	Set oValor.ordem = $Piece(campoMV,"*",2)
		        	Set oValor.mnemonicoExame = $Extract(pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.GetAt(cCam).Descricao,1,10)
		        	
		        	If $PIECE($NAMESPACE,"_",1) = "MATERDEI" 
		        	{
			        	Set resultadoExame = $EXTRACT(valorExame,1,300)
			    		If $LENGTH(valorExame) > 300
			    		{
			    			Set resultadoExame = $PIECE(resultadoExame," ",1,*-1)
			    		}
		        	} 
		        	Else 
		        	{
			        	Set resultadoExame = valorExame
			        }
		    		Set oValor.resultadoExame = $Case(resultadoExame,"":"-",:resultadoExame)
		    		If $PIECE($NAMESPACE,"_",1) = "MATERDEI"  
		    		{
			    		Set valorExame = $EXTRACT(valorExame,$length(resultadoExame)+1,*)
		    		} 
		    		Else 
		    		{
	        			Set oValor.resultadoExame = $Case(valorExame,"":"-",:valorExame)
	        			Set valorExame = ""
		    		}
	        		
	        		Set oValor.unidadeReferencia 			= pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.GetAt(cCam).UnMedida
	        		Set oValor.mascara 						= ""
	        		Set oValorRef       					= ##class(shift.xml.mv.cma.ValorReferencia).%New()
		            Set oNormal         					= ##class(shift.xml.mv.cma.normal).%New()
		            Set oAbsolutoNormal 					= ##class(shift.xml.mv.cma.absolutoNormal).%New()
		            Set oAbsolutoNormal.descricao      		= "VALOR NORMAL ABSOLUTO"
		            ;Set oAbsolutoNormal.valorInicio    		= pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.GetAt(cCam).LimiteInferior
		            ;Set oAbsolutoNormal.valorFim       		= pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.GetAt(cCam).LimiteSuperior
		            
		            Set oNormal.absolutoNormal         		= oAbsolutoNormal
		            Set oPercNormal     					= ##class(shift.xml.mv.cma.percentualNormal).%New()
		            Set oPercNormal.descricao          		= "PERCENTUAL NORMAL"
		            Set oPercNormal.valorInicio        		= ""
		            Set oPercNormal.valorFim           		= ""   
		            Set oNormal.percentualNormal       		= oPercNormal
		            Set oNormal.textoReferencia				= $EXTRACT(pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.GetAt(cCam).VlReferencia,1,3999)
		            Set oLimite         					= ##class(shift.xml.mv.cma.limite).%New()
		            Set oAbsolutoLimite = ##class(shift.xml.mv.cma.absolutoLimite).%New()
		            Set oAbsolutoLimite.descricao      		= "VALOR LIMITE ABSOLUTO"
		            Set oAbsolutoLimite.valorInicio    		= ""
		            Set oAbsolutoLimite.valorFim       		= ""
		            Set oLimite.absolutoLimite         		= oAbsolutoLimite
		            Set oPercLimite     					= ##class(shift.xml.mv.cma.percentualLimite).%New()
		            Set oPercLimite.descricao          		= "PERCENTUAL LIMITE"
		            Set oPercLimite.valorInicio        		= ""
		            Set oPercLimite.valorFim           		= ""
		            Set oLimite.percentualLimite       		= oPercLimite
		            Set oAbsurdo        					= ##class(shift.xml.mv.cma.absurdo).%New()
		            Set oAbsolAbsurdo   					= ##class(shift.xml.mv.cma.absolutoAbsurdo).%New()
		            Set oAbsolAbsurdo.descricao        		= "VALOR ABSURDO ABSOLUTO"
		            Set oAbsolAbsurdo.valorInicio      		= ""
		            Set oAbsolAbsurdo.valorFim         		= ""
		            Set oAbsurdo.absolutoAbsurdo       		= oAbsolAbsurdo
		            Set oPercAbsurdo    = ##class(shift.xml.mv.cma.percentualAbsurdo).%New()
		            Set oPercAbsurdo.descricao 				= "PERCENTUAL ABSURDO"
		            Set oPercAbsurdo.valorInicio       		= ""
		            Set oPercAbsurdo.valorFim          		= ""
		            Set oAbsurdo.percentualAbsurdo     		= oPercAbsurdo
		            Set oValorRef.absurdo 					= oAbsurdo
		            Set oValorRef.limite  					= oLimite
		            Set oValorRef.normal  					= oNormal
		            Set oValor.ValorReferencia 				= oValorRef
		            Set Status = oExame.listaValor.Insert(oValor)
		            If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
		            Set oExame.assinado = "S"
		            Set oExame.revisado = "S"
		            Set oExame.liberado = "S"
	        	}
	        	
	        	Set sqlMascaraObs = "SELECT CampoCliente FROM dado_shifthis_mv.TblDeParaMascara "_
	        						"WHERE CampoApoio = ? AND CodExameApoio = ? AND CampoCliente IS NOT NULL"
	        						
	        	Set tStatMascaraObs= ##class(%SQL.Statement).%New()
		        Set Status = tStatMascaraObs.%Prepare(sqlMascaraObs)
		        If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
		        Set rsetMascaraObs = tStatMascaraObs.%Execute("OBS_G",rset.CodExameApoio)
		        Set campoMVObs = 0
		        
		        If rsetMascaraObs.%Next()
		        {
			        Set campoMVObs = rsetMascaraObs.CampoCliente
		        }
	        	
	        	If (cCam = qtdCampo && $Find(campoMVObs,"*") > 0)
	        	{
		        	Set valorExame = pRequest.ResultadoCliente.Exame.GetAt(1).Observacao
	        	
		        	Set alteraSequencia = 1
		        	
		        	Set contador = 0
		        	Set qtdBlocosResExame = $PIECE(campoMVObs,"*",2) 
					
					If valorExame = "" 
					{ 
						Set valorExame = "(VAZIO-SHIFT)" 
					}
					
		        	While (valorExame '= "")
		        	{			        	
			        	If valorExame = "(VAZIO-SHIFT)" 
			        	{ 
			        		Set valorExame = "" 
			        	}
		        		If alteraSequencia 
		        		{
			        		If contador = 0 
			        		{
			        			Set qtdBlocosResExame = $PIECE(campoMVObs,"*",2) 
			        			Set contador = contador + 1
			        		}
			        		Else
			        		{
				        		Set qtdBlocosResExame = qtdBlocosResExame + 1
			        		}
			        		Set campoMV = $PIECE(campoMVObs,"*",1)_"*"_qtdBlocosResExame
		        		}
			        	
			        	Set oValor = ##class(shift.xml.mv.cma.Valor).%New()
			        	Set oValor.versao = $Piece(campoMV,"*",1)
			        	Set oValor.ordem = $Piece(campoMV,"*",2)
			        	
			        	Set oValor.mnemonicoExame = "Observação"
			        	
			        	// [SERV-20848]
			        	If $PIECE($NAMESPACE,"_",1) = "MATERDEI"  {
			        		Set resultadoExame = $EXTRACT(valorExame,1,300)
				    		If $LENGTH(valorExame) > 300{
				    			Set resultadoExame = $PIECE(resultadoExame," ",1,*-1)
				    		}
			        	} Else {
				        	Set resultadoExame = valorExame
				        }
			    		Set oValor.resultadoExame				= $Case(resultadoExame,"":"-",:resultadoExame)
			    		If $PIECE($NAMESPACE,"_",1) = "MATERDEI"  {
		        			Set valorExame = $EXTRACT(valorExame,$length(valorExame)+1,*)
			    		} Else {
				    		Set valorExame = ""	
				    	}
		        		
		        		Set oValor.unidadeReferencia 			= ""
		        		Set oValor.mascara 						= ""
		        		Set oValorRef       					= ##class(shift.xml.mv.cma.ValorReferencia).%New()
			            Set oNormal         					= ##class(shift.xml.mv.cma.normal).%New()
			            Set oAbsolutoNormal 					= ##class(shift.xml.mv.cma.absolutoNormal).%New()
			            Set oAbsolutoNormal.descricao      		= ""
			            Set oAbsolutoNormal.valorInicio    		= ""
			            Set oAbsolutoNormal.valorFim       		= ""
			            			            
			            Set oNormal.absolutoNormal         		= oAbsolutoNormal
			            Set oPercNormal     					= ##class(shift.xml.mv.cma.percentualNormal).%New()
			            Set oPercNormal.descricao          		= ""
			            Set oPercNormal.valorInicio        		= ""
			            Set oPercNormal.valorFim           		= ""   
			            Set oNormal.percentualNormal       		= oPercNormal
			            Set oLimite         					= ##class(shift.xml.mv.cma.limite).%New()
			            Set oAbsolutoLimite = ##class(shift.xml.mv.cma.absolutoLimite).%New()
			            Set oAbsolutoLimite.descricao      		= ""
			            Set oAbsolutoLimite.valorInicio    		= ""
			            Set oAbsolutoLimite.valorFim       		= ""
			            Set oLimite.absolutoLimite         		= oAbsolutoLimite
			            Set oPercLimite     					= ##class(shift.xml.mv.cma.percentualLimite).%New()
			            Set oPercLimite.descricao          		= ""
			            Set oPercLimite.valorInicio        		= ""
			            Set oPercLimite.valorFim           		= ""
			            Set oLimite.percentualLimite       		= oPercLimite
			            Set oAbsurdo        					= ##class(shift.xml.mv.cma.absurdo).%New()
			            Set oAbsolAbsurdo   					= ##class(shift.xml.mv.cma.absolutoAbsurdo).%New()
			            Set oAbsolAbsurdo.descricao        		= ""
			            Set oAbsolAbsurdo.valorInicio      		= ""
			            Set oAbsolAbsurdo.valorFim         		= ""
			            Set oAbsurdo.absolutoAbsurdo       		= oAbsolAbsurdo
			            Set oPercAbsurdo    = ##class(shift.xml.mv.cma.percentualAbsurdo).%New()
			            Set oPercAbsurdo.descricao 				= ""
			            Set oPercAbsurdo.valorInicio       		= ""
			            Set oPercAbsurdo.valorFim          		= ""
			            Set oAbsurdo.percentualAbsurdo     		= oPercAbsurdo
			            Set oValorRef.absurdo 					= oAbsurdo
			            Set oValorRef.limite  					= oLimite
			            Set oValorRef.normal  					= oNormal
			            Set oValor.ValorReferencia 				= oValorRef
			            Set Status = oExame.listaValor.Insert(oValor)
			            If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
			            Set oExame.assinado = "S"
			            Set oExame.revisado = "S"
			            Set oExame.liberado = "S"
		        	}
	        	}
	        	
        	}
        	Set Status = oResultado.listaExame.Insert(oExame)
        	If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
        	Set oMensagem.Resultado = oResultado
        	Set pResponse.ResultadoMV = oMensagem
        }
        Set pResponse.TipoResultado = "N"
    }    
    Catch objErro
    {
        Set Status = ##class(shift.utl.TrataExcecao).Excecao(objErro)
        Set msgErro = $System.Status.GetOneErrorText(Status)
        Set pResponse.Retorno = 0
        Set pResponse.DescricaoErro = msgErro
        $$$LOGWARNING(msgErro)
    }   
    Quit $System.Status.OK()
}

Method ConverteResultadoCultura(pRequest As shift.msg.ConverteResCulturaRequest, Output pResponse As shift.msg.ConverteResCulturaResponse) As %Status
{
    Try
    {
		Set Status = $$$OK
        Set cControleErro = 0
        Set msgErro = ""
        Set msgErroGeral = ""   
        Set pResponse = ##class(shift.msg.ConverteResCulturaResponse).%New()     
        #DIM oControlePedido As dado.shifthis.mv.TblControlePedido

        Set objIntegracao = ##class(dado.shifthis.mv.TblIntegracao).%OpenId(pRequest.IdIntegracao,,.Status)                
        If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
        
        Set oControlePedido = ##class(dado.shifthis.mv.TblControlePedido).%OpenId(pRequest.IdControlePedido,,.Status)
        If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
        
        Set sql = 	"SELECT "_
        				"CodigoItemPedido, "_
        				"DescExame, "_
        				"Material, "_
        				"DescricaoMaterial, "_
        				"DeParaExame->CodExameApoio, "_
        				"DeParaExame->ProcedimentoTSACliente, "_
        				"Tipo, "_
        				"Situacao "_
        			"FROM "_
        				"dado_shifthis_mv.TblControleExame "_
        			"WHERE "_
        				"ControlePedido = ? "_
        				"AND (CodExameCliente = ? OR DeParaExame->CodExameCliente = ?) "
        
        Set tStatement = ##class(%SQL.Statement).%New()
        Set Status = tStatement.%Prepare(sql)
        If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
        Set rset = tStatement.%Execute(pRequest.IdControlePedido,pRequest.ResultadoCliente.Exame.GetAt(1).Codigo,pRequest.ResultadoCliente.Exame.GetAt(1).Codigo)
        
        If rset.%Next()
        {
	        Set observacaoExame = ""
	        Set oMensagem = ##class(shift.xml.mv.cul.Mensagem).%New()
	        Set oCabecalho = ##class(shift.xml.mv.cul.Cabecalho).%New()
	        Set oCabecalho.mensagemID = oControlePedido.MensagemID
        	Set oCabecalho.versaoXML = $Case(oControlePedido.VersaoXML,"":1,:$ZStrip(oControlePedido.VersaoXML,"*C"))
	        Set oCabecalho.identificacaoCliente = oControlePedido.IdentificacaoCliente
	        Set oCabecalho.servico = "RESULTADO_EXAME_CULTURA"
	        Set oCabecalho.dataHora = $ZDateTime($Horolog,3)
	        Set oCabecalho.empresaOrigem = objIntegracao.EmpresaOrigem        
	        Set oCabecalho.sistemaOrigem = objIntegracao.SistemaOrigem
	        Set oCabecalho.empresaDestino = objIntegracao.EmpresaDestino
	        Set oCabecalho.sistemaDestino = objIntegracao.SistemaDestino
	        Set oCabecalho.usuario = objIntegracao.UsuarioMV
	        Set oCabecalho.senha = objIntegracao.SenhaMV
	        Set oMensagem.Cabecalho = oCabecalho
	        Set oResultado = ##class(shift.xml.mv.cul.ResultadoCultura).%New()
	        
	        Set exameExportado = ..ExameExportado(pRequest.IdIntegracao,pRequest.ResultadoCliente.Pedido.OrdemServico,pRequest.ResultadoCliente.Exame.GetAt(1).Codigo)
	        If exameExportado
	        {
				Set oResultado.operacao = "A"
			}
			Else
			{
				Set oResultado.operacao = "I"
			}
	        Set oResultado.codigoPaciente = oControlePedido.CodigoPaciente
        	Set oResultado.codigoPacienteDePara = ""
        	Set oResultado.nome = pRequest.ResultadoCliente.Paciente.Nome
        	Set oSolicitacao = ##class(shift.xml.mv.cul.solicitacao).%New()
        	Set oAtendimento = ##class(shift.xml.mv.cul.atendimento).%New()
        	Set oAtendimento.codigoAtendimento = oControlePedido.CodigoAtendimento
        	Set oAtendimento.codigoAtendimentoDePara = ""
        	Set oSolicitacao.atendimento = oAtendimento
        	Set oPedido = ##class(shift.xml.mv.cul.pedido).%New()
        	Set oPedido.codigoPedido = $Piece(pRequest.ResultadoCliente.Pedido.OrdemServico,"*",2)
        	Set oPedido.codigoPedidoDePara = pRequest.ResultadoCliente.Pedido.OrdemServicoApoio
        	Set oPedido.codigoLaboratorio = "1"
        	Set oPedido.codigoLaboratorioDePara = ""
        	Set oPedido.prestadorSolicitante = oControlePedido.PrestadorSolicitante
        	Set oPedido.prestadorSolicitanteDePara = ""
        	Set oPedido.setorSolicitante = oControlePedido.PostoCliente
        	Set oPedido.setorSolicitanteDePara = oControlePedido.PostoApoio
        	;Set oPedido.observacao = pRequest.ResultadoCliente.Exame.GetAt(1).Observacao
        	//T0800-44753
        	Set oPedido.observacao = ""
        	Set oSolicitacao.pedido = oPedido
        	Set oResultado.solicitacao = oSolicitacao
        	Set oExame = ##class(shift.xml.mv.cul.Exame).%New()
        	Set oExame.codigoItemPedido = rset.CodigoItemPedido
        	Set oExame.codigoItemPedidoDePara = ""
        	Set oExame.codigoExame = pRequest.ResultadoCliente.Exame.GetAt(1).Codigo
        	Set oExame.codigoExameDePara = rset.CodExameApoio
        	Set oExame.descExame = rset.DescExame
        	Set oExame.mnemonico = pRequest.ResultadoCliente.Exame.GetAt(1).Mnemonico
        	Set oExame.codigoMaterial = $Case(rset.Material,"":1,:$ZStrip(rset.Material,"*C"))
        	Set oExame.codigoMaterialDePara = ""
        	Set oExame.descMaterial = rset.DescricaoMaterial
        	;Set oExame.observacao = $EXTRACT(pRequest.ResultadoCliente.Exame.GetAt(1).Observacao,1,150)
        	Set oExame.observacao = pRequest.ResultadoCliente.Exame.GetAt(1).Observacao
        	Set oExame.versao = ""
        	Set oExame.ordem = ""
        	
        	If (pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.GetAt(1).ResultadoParcial = 1) 
        	{
        		Set oExame.parcial = "S" 
        	}
        	Else
        	{
	        	Set oExame.parcial = "N" 
        	}
        	
        	If exameExportado
        	{
	        	Set oExame.retificado = "S"
        	}
        	
        	Set culturaPositiva = pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.GetAt(1).CulturaPositiva

        	If (pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.GetAt(1).ResultadoParcial) 
        	{
	        	Set lvalorResultado = $LISTFROMSTRING($ZCONVERT(pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.GetAt(1).Valor,"U")," ")
	        	Set oExame.resultadoCulturaExame = "A" // Positivo em Andamento
	        	If $LF(lvalorResultado,"NEGATIVO") Set oExame.resultadoCulturaExame =  "B" // Negativo em Andamento
	        } 
	        Else 
	        {
		        // P - Positivo
		        // N - Negativo
		        // F - Flora Mista
        		Set vResultadoCulturaExame = $SELECT(culturaPositiva=1:"P",culturaPositiva=0:"N",1:"")        		

        		Set Status = ##Class(dado.shifthis.mv.TblDeParaMicroorganismo).RetornaFloraMistaMicroorganismoCliente(objIntegracao.%Id(), pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.GetAt(1).ValorId, .vFloraMista)
        		If $System.Status.IsError(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
        		
        		If (vFloraMista = 1)
        		{
	        		Set vResultadoCulturaExame = "F"
	        		Set observacaoExame = "Crescimento de flora mista"
        		}
        		
        		Set oExame.resultadoCulturaExame = vResultadoCulturaExame
	        }
	        
	        If (observacaoExame = "")
	        {
		        Set observacaoExame = $EXTRACT(pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.GetAt(1).Valor,1,150)
	        }
	        Set oExame.observacao = observacaoExame
	        
        	Set oResultadoCultura = ##class(shift.xml.mv.cul.Resultado).%New()
        	        	
        	Set qtdResultadoCultura = pRequest.ResultadoCliente.Exame.GetAt(1).ResultadoCultura.Count()
        	
        	For cExame=1:1:qtdResultadoCultura
        	{
	        	Set oResultadoCultura = ##class(shift.xml.mv.cul.Resultado).%New()
	        	If ((oExame.resultadoCulturaExame = "P") || (oExame.resultadoCulturaExame = "F")) // Positivo //Flora Mista
	        	{
					If '$IsObject(pRequest.ResultadoCliente.Exame.GetAt(1).ResultadoCultura.GetAt(cExame))
					{
						Set oResultadoCultura.codigoGerme = pRequest.ResultadoCliente.Exame.GetAt(1).ResultadoCultura.GetAt(cExame).CodMicroorganismo
						Set oResultadoCultura.codigoGermeDePara = ""
						Set oResultadoCultura.codigoProcedimento = rset.ProcedimentoTSACliente
						Set oResultadoCultura.codigoProcedimentoDePara = ""
						Set tColonia = pRequest.ResultadoCliente.Exame.GetAt(1).ResultadoCultura.GetAt(cExame).ContagemColonias
		            	Set oResultadoCultura.codigoColonia = "" 
						Set oResultadoCultura.descColonia = tColonia
						Set oResultadoCultura.codigoColoniaDePara = ""
						Set oResultadoCultura.observacaoGerme = pRequest.ResultadoCliente.Exame.GetAt(1).ResultadoCultura.GetAt(cExame).Observacao
					}
					Else
					{
			        	Set oResultadoCultura.codigoGerme = pRequest.ResultadoCliente.Exame.GetAt(1).ResultadoCultura.GetAt(cExame).CodMicroorganismo
		            	Set oResultadoCultura.codigoGermeDePara = ""
		            	Set oResultadoCultura.codigoProcedimento = rset.ProcedimentoTSACliente
		            	Set oResultadoCultura.codigoProcedimentoDePara = ""
		            	Set tColonia = pRequest.ResultadoCliente.Exame.GetAt(1).ResultadoCultura.GetAt(cExame).ContagemColonias
		            	Set oResultadoCultura.codigoColonia = "" 
		            	Set oResultadoCultura.descColonia = tColonia
		            	Set oResultadoCultura.codigoColoniaDePara = ""
		            	Set oResultadoCultura.observacaoGerme = pRequest.ResultadoCliente.Exame.GetAt(1).ResultadoCultura.GetAt(cExame).Observacao
		            	
		            	Set qtdAntimicrobiano = pRequest.ResultadoCliente.Exame.GetAt(1).ResultadoCultura.GetAt(cExame).Antimicrobiano.Count()
		            	For cAmi=1:1:qtdAntimicrobiano
		            	{
			            	Set oResultadoTeste = ##class(shift.xml.mv.cul.ResultadoTeste).%New()
		                	Set oResultadoTeste.codigoAntimicrobiano = pRequest.ResultadoCliente.Exame.GetAt(1).ResultadoCultura.GetAt(cExame).Antimicrobiano.GetAt(cAmi).Apelido
		                	Set oResultadoTeste.codigoAntimicrobianoDePara = ""
		                	Set oResultadoTeste.valorAntimicrobiano = pRequest.ResultadoCliente.Exame.GetAt(1).ResultadoCultura.GetAt(cExame).Antimicrobiano.GetAt(cAmi).Mic
		                	
		                	Set antimicrobiano = $Extract(pRequest.ResultadoCliente.Exame.GetAt(1).ResultadoCultura.GetAt(cExame).Antimicrobiano.GetAt(cAmi).Classificacao,1,1)
		                	If (antimicrobiano = "I") 
		                	{
		                		Set antimicrobiano = "M"
		                	}
		                	
		                	Set oResultadoTeste.valorResultado = antimicrobiano 
		                	Set oResultadoTeste.resultadoAntimicrobiano = antimicrobiano 

		                	Set Status = oResultadoCultura.listaResultadoTeste.Insert(oResultadoTeste)
		                	If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
		            	}
					}
					
					If '$IsObject(pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.GetAt(cExame)) Continue
					
					If (pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.GetAt(cExame).AntibiogramaNaoRealizado
						 && (qtdResultadoCultura>1)
						 && (oResultadoCultura.listaResultadoTeste.Count() = 0)) 
					{
		            	Set oResultadoTeste = ##class(shift.xml.mv.cul.ResultadoTeste).%New()
	                	Set Status = oResultadoCultura.listaResultadoTeste.Insert(oResultadoTeste)
	                	If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
		        	}
	        	}
		        
		        If (objIntegracao.ExportaUsuariosDadosMV)
        		{
	        		Set Status = ..PreparaDadosOperadorMVCultura(objIntegracao, pRequest.ResultadoCliente.Exame.GetAt(1), .oResultadoCultura)
        		}
		        
		        If (pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.GetAt(1).ResultadoParcial = 1) 
		        {
		        	Set oResultadoCultura.assinado = "N"
					Set oResultadoCultura.revisado = "S"
					Set oResultadoCultura.liberado = "S"
		        }
		        
				Set Status = ..PreparaDadosOperadorCultura(
									rset.CodExameApoio, 
									pRequest.ResultadoCliente.Pedido.OrdemServicoApoio, 
									pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.GetAt(1).ResultadoParcial, 
									objIntegracao, 
									pRequest.ResultadoCliente.Exame.GetAt(1), 
									.oResultadoCultura)

	        	If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
		        Set Status = oExame.listaResultado.Insert(oResultadoCultura)
		        If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
        	}
        	
        	If (qtdResultadoCultura = 0)
        	{
	        	Set oResultadoCultura = ##class(shift.xml.mv.cul.Resultado).%New()
	        	
	        	If (objIntegracao.ExportaUsuariosDadosMV)
        		{
	        		Set Status = ..PreparaDadosOperadorMVCultura(objIntegracao, pRequest.ResultadoCliente.Exame.GetAt(1), .oResultadoCultura)
        		}
	        	Else
	        	{
		        	Set Status = ..PreparaDadosOperadorCultura(
									rset.CodExameApoio, 
									pRequest.ResultadoCliente.Pedido.OrdemServicoApoio, 
									pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.GetAt(1).ResultadoParcial, 
									objIntegracao, 
									pRequest.ResultadoCliente.Exame.GetAt(1), 
									.oResultadoCultura)
	        	}
	        	
	        	If (pRequest.ResultadoCliente.Exame.GetAt(1).Resultado.GetAt(1).ResultadoParcial = 1) 
		        {
		        	Set oResultadoCultura.assinado = "N" 
					Set oResultadoCultura.revisado = "S" 
					Set oResultadoCultura.liberado = "S" 
		        }

				If (oExame.parcial = "N")
		        {
		        	Set oResultadoCultura.assinado = "S" 
					Set oResultadoCultura.revisado = "S" 
					Set oResultadoCultura.liberado = "S" 
			    }

	        	
				If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
		        Set Status 	= oExame.listaResultado.Insert(oResultadoCultura)
		        If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)	        	
        	}
        			    
	        Set Status 	= oResultado.listaExame.Insert(oExame)
	        If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
	        Set oMensagem.ResultadoCultura   = oResultado
	        Set pResponse.ResultadoCulturaMV = oMensagem
        }
        Set pResponse.TipoResultado = "C"
    }    
    Catch objErro
    {
        Set tSC = ##class(shift.utl.TrataExcecao).Excecao(objErro)
        Set msgErro = $System.Status.GetOneErrorText(tSC)
        Set pResponse.Retorno = 0
        Set pResponse.DescricaoErro = msgErro
        $$$LOGWARNING(msgErro)
    }   
    
    Quit $$$OK
}

ClassMethod ExameExportado(pIntegracao As %String, pOrdemServico As %String, pCodigoExame As %String) As %Boolean
{

	Set exportado = 0
	
	Try 
	{
		Set sqlExportado = "SELECT TOP 1 ID FROM dado_shifthis_mv.TblControleExame "_
				 	"WHERE ControlePedido->Integracao = ? "_
					"AND ControlePedido->OrdemServico = ? "_
					"AND CodExameCliente = ? "_
					"AND Tipo = ? AND ExportadoMV = ? AND ResultadoParcial = ?"

		Set tStatementExportado = ##class(%SQL.Statement).%New()
		Set Status = tStatementExportado.%Prepare(sqlExportado)
		If $System.Status.IsError(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
	    
	    Set rsetExportado = tStatementExportado.%Execute(pIntegracao,pOrdemServico,pCodigoExame,1,1,0)
	    If rsetExportado.%Next() 
	    {
	    	Set exportado = 1
	    }
	}
	Catch(ex) 
	{
		Throw ex.AsStatus()
    }
    
	Quit exportado
}

Method ConverteObjCancelamento(pRequest As shift.msg.ConverteObjCancelamentoRequest, pResponse As shift.msg.ConverteObjCancelamentoResponse) As %Status
{
    Try
    {
        Set Status = $$$OK
        Set pResponse = ##class(shift.msg.ConverteObjCancelamentoResponse).%New()
        
        Set objIntegracao = ##class(dado.shifthis.mv.TblIntegracao).%OpenId(pRequest.IdIntegracao)
        If '$ISOBJECT(objIntegracao)
        {
        	Set msgErro = "Integração "_pRequest.IdIntegracao_" não encontrada."
    		Set Status = $$$ERROR(5001,msgErro)
        	Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
        }
        
        Set ordemServicoApoio = ""
        Set idControlePedido = ""
        Set sql = "SELECT TOP 1 ID,OrdemServicoApoio FROM dado_shifthis_mv.TblControlePedido "_
			 	  "WHERE Integracao = ? "_
				  "AND OrdemServico = ? "				
		Set tStatement = ##class(%SQL.Statement).%New()
		Set Status = tStatement.%Prepare(sql)
		If $System.Status.IsError(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
	    
	    Set rset = tStatement.%Execute(pRequest.IdIntegracao,pRequest.PedidoMV.PedidoExame.Atendimento.CodigoAtendimento_"*"_pRequest.PedidoMV.PedidoExame.CodigoPedido)
	    If rset.%Next()
	    {
			Set ordemServicoApoio = rset.OrdemServicoApoio
			Set idControlePedido = rset.ID
	    }
	    Else
	    {
		    Set msgErro = "Ordem de serviço apoio do pedido "_pRequest.PedidoMV.PedidoExame.Atendimento.CodigoAtendimento_"*"_pRequest.PedidoMV.PedidoExame.CodigoPedido_" não encontrada."
    		Set Status = $$$ERROR(5001,msgErro)
        	Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
	    }
        Set reqCancelamento = ##class(shift.xml.lis.can.Requisicao).%New()
        Set reqCancelamento.PedidoLab = pRequest.PedidoMV.PedidoExame.Atendimento.CodigoAtendimento_"*"_pRequest.PedidoMV.PedidoExame.CodigoPedido
        Set reqCancelamento.Integracao = objIntegracao.Nome
        Set reqCancelamento.CodigoOs = ordemServicoApoio
        
        Set qtdeExames = pRequest.PedidoMV.PedidoExame.Exames.Exame.Count()
        
        If (qtdeExames = 0)
        {
	        Set msgErro = "É obrigatório o envio de pelo menos um exame para cancelamento."
    		Set Status = $$$ERROR(5001,msgErro)
        	Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
        }
        
        For contEx=1:1:qtdeExames
        {	        
			Set sqlExame = "SELECT DeParaExame->CodExameApoio As CodExameApoio FROM dado_shifthis_mv.TblControleExame WHERE ControlePedido = ? AND CodExameCliente = ?"
	        Set tStatementExame = ##class(%SQL.Statement).%New()
	        Set Status = tStatementExame.%Prepare(sqlExame)
	        If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
	        	        
	        Set rsetExame = tStatementExame.%Execute(idControlePedido,pRequest.PedidoMV.PedidoExame.Exames.Exame.GetAt(contEx).CodigoExame)
	        If rsetExame.%Next()
	        {	        	        
		        Set objProcedimento = ##class(shift.xml.lis.can.Procedimento).%New()
		        Set objProcedimento.Codigo = rsetExame.CodExameApoio
		        Do reqCancelamento.Procedimentos.Insert(objProcedimento)
	        }
	        Else
	        {
		        Set msgErro = "Exame "_pRequest.PedidoMV.PedidoExame.Exames.Exame.GetAt(contEx).CodigoExame_" não encontrado no pedido original."
    			Set Status = $$$ERROR(5001,msgErro)
        		Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
	        }
        }
        Set pResponse.RequisicaoCancelamento = reqCancelamento        
    }
    Catch objErro
    {
        Set tSC = ##class(shift.utl.TrataExcecao).Excecao(objErro)
        Set msgErro = $System.Status.GetOneErrorText(tSC)
        Set pResponse.Retorno = 0
        Set pResponse.DescricaoErro = msgErro
        $$$LOGWARNING(msgErro)
    }   
    Quit $$$OK
}

Method ConverteStatus(pRequest As shift.msg.shifthis.ConverteStatusRequest, Output pResponse As shift.msg.shifthis.ConverteStatusResponse) As %Status
{
	
	 Try
    {
        Set Status = $$$OK
        Set cControleErro = 0
        Set msgErro = ""
        Set msgErroGeral = ""   
        Set pResponse = ##class(shift.msg.shifthis.ConverteStatusResponse).%New()
        
        Set objIntegracao = ##class(dado.shifthis.mv.TblIntegracao).IdxNomeOpen(pRequest.IdIntegracao)
        If '$ISOBJECT(objIntegracao)
        {
        	Set msgErro = "Integração "_pRequest.IdIntegracao_" não encontrada."
    		Set Status = $$$ERROR(5001,msgErro)
        	Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
        }
      	       
        Set sql = "SELECT ID FROM dado_shifthis_mv.TblControlePedido WHERE OrdemServicoApoio = ? AND Integracao = ? "
        Set tStatement = ##class(%SQL.Statement).%New()
        Set Status = tStatement.%Prepare(sql)
        If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
        
        Set rset = tStatement.%Execute(pRequest.DadosLIS.CodigoOs, objIntegracao.%Id())
        If rset.%Next()
        {
	        Set controlePedido = rset.ID
	        Set oControlePedido = ##class(dado.shifthis.mv.TblControlePedido).%OpenId(controlePedido,,.Status)
        	If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
	        
            Set oMensagem = ##class(shift.xml.mv.cma.MensagemStatus).%New()
            Set oCabecalho = ##class(shift.xml.mv.cma.Cabecalho).%New()
            Set oCabecalho.mensagemID = oControlePedido.MensagemID
	        Set oCabecalho.versaoXML = $Case(oControlePedido.VersaoXML,"":1,:$ZStrip(oControlePedido.VersaoXML,"*C"))
	        Set oCabecalho.identificacaoCliente = oControlePedido.IdentificacaoCliente
	        Set oCabecalho.servico = "AMOSTRA_EXAME"
	        Set oCabecalho.dataHora = $ZDateTime($Horolog,3)
	        Set oCabecalho.empresaOrigem = objIntegracao.EmpresaOrigem        
	        Set oCabecalho.sistemaOrigem = objIntegracao.SistemaOrigem
	        Set oCabecalho.empresaDestino = objIntegracao.EmpresaDestino
	        Set oCabecalho.sistemaDestino = objIntegracao.SistemaDestino
	        Set oCabecalho.usuario = objIntegracao.UsuarioMV
	        Set oCabecalho.senha = objIntegracao.SenhaMV
	        Set oMensagem.Cabecalho = oCabecalho
	        
	        Set qtdExames = pRequest.DadosLIS.Exames.Count()
	        
	        For exames=1:1:qtdExames 
	        {		        
		        Set qtdAmostra = pRequest.DadosLIS.Exames.GetAt(exames).Amostras.Count()
		        For amostra=1:1:qtdAmostra 
		        {	        
			        Set oAmostra = ##class(shift.xml.mv.cma.AmostraStatus).%New()
			        
			        If (pRequest.Log = "002" || pRequest.Log = "003") 
			        {
				        Set oAmostra.operacao = "E"
				        Set oAmostra.situacaoAmostra = "C"
				        Set oAmostra.confirmada = "N"
			        }
			        Else
			        {
				        If (pRequest.Log = "060" || pRequest.Log = "100") 
				        {
					        Set oAmostra.operacao = "I"
					        Set oAmostra.situacaoAmostra = "A"
					        Set oAmostra.dataColeta = pRequest.DadosLIS.Exames.GetAt(exames).DataEvento_" "_pRequest.DadosLIS.Exames.GetAt(exames).HoraEvento
					        Set oAmostra.horaColeta = pRequest.DadosLIS.Exames.GetAt(exames).DataEvento_" "_pRequest.DadosLIS.Exames.GetAt(exames).HoraEvento
					        Set oAmostra.usuarioColeta = pRequest.DadosLIS.Exames.GetAt(exames).UsuarioEvento
					        If pRequest.Log = "060"
					        {
					        	Set oAmostra.confirmada = "S"
					        }
					        Else
					        {
						        Set oAmostra.confirmada = "N"
					        }
				        }
				        Else 
				        {
					        Set oAmostra.operacao = "A"
					        If pRequest.Log = "007" 
					        {
						        Set oAmostra.situacaoAmostra = "R"
						        Set oAmostra.confirmada = "N"
					        }
					        Else
					        {
						        Set oAmostra.situacaoAmostra = "D"
						        Set oAmostra.confirmada = "S"
					        }
				        }
			        }
			        
					Set oAmostra.codigoAmostra = pRequest.DadosLIS.Exames.GetAt(exames).Amostras.GetAt(amostra).Cbarra
			        Set oAmostra.codigoAmostraDePara = pRequest.DadosLIS.Exames.GetAt(exames).Amostras.GetAt(amostra).Cbarra
			        Set oAmostra.codigoAmostraPAI = ""
			        Set oAmostra.codigoAmostraPAIDepara = ""
			        Set oAmostra.descricaoEtiqueta = "teste"	
			        
			        Set oAtendimento = ##class(shift.xml.mv.cma.atendimentoStatus).%New()
			        
			        Set sql1 = "SELECT Descricao FROM dado_shifthis_mv.TblDeParaConvenio WHERE ConvenioCliente = ? AND Integracao = ? AND Situacao = ?"
        			Set tStatement1 = ##class(%SQL.Statement).%New()
        			Set Status = tStatement1.%Prepare(sql1)
        			If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
        			
        			Set rset1 = tStatement1.%Execute(oControlePedido.ConvenioCliente,pRequest.IdIntegracao,1)
        			If rset1.%Next()
        			{
	        			Set oAtendimento.codigoConvenio    = oControlePedido.ConvenioCliente
			        	Set oAtendimento.descConvenio      = rset1.Descricao
        			}
			        
			        Set oAtendimento.codigoAtendimento = $PIECE(pRequest.DadosLIS.PedidoCliente,"*",1)
			        Set oAtendimento.codigoPaciente    = oControlePedido.CodigoPacienteCliente
			        Set oAtendimento.nomePaciente      = oControlePedido.NomePaciente
			        Set oAtendimento.dataNascimento    = $ZDATE(oControlePedido.DataNascimentoPaciente,3)
			        Set oAtendimento.sexoPaciente      = ""
			        
			        
			        Set oPedido = ##class(shift.xml.mv.cma.pedidoStatus).%New()
			        Set oPedido.codigoPedido = $PIECE(pRequest.DadosLIS.PedidoCliente,"*",2)
			        Set oPedido.codigoSetor  = pRequest.DadosLIS.Exames.GetAt(exames).SetorExame
			        Set oPedido.dataPedido   = $ZDATE(oControlePedido.Data,3)
			        
			        Set sqlExame = "SELECT CodigoItemPedido,DescExame,Material,DescricaoMaterial,Recipiente,DeParaExame->CodExameApoio FROM dado_shifthis_mv.TblControleExame WHERE ControlePedido = ? AND CodExameCliente = ?"
			        Set tStatementExame = ##class(%SQL.Statement).%New()
			        Set Status = tStatementExame.%Prepare(sqlExame)
			        If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
			        
			        Set rsetExame = tStatementExame.%Execute(controlePedido, pRequest.DadosLIS.Exames.GetAt(exames).Codigo)
			        If rsetExame.%Next()
			        {
						Set oAmostra.codigoMaterial         = rsetExame.Material
				        Set oAmostra.descMaterial           = ""
				        Set oAmostra.codigoTuboColeta       = rsetExame.Recipiente
				        Set oAmostra.descTuboColeta         = ""
				        
				        Set oExame = ##class(shift.xml.mv.cma.ExameStatus).%New()
				       
					   	Set oExame.operacao      	= oAmostra.operacao
					   	Set oExame.codigoItemPedido = rsetExame.CodigoItemPedido
					    Set oExame.codigoExame   	= pRequest.DadosLIS.Exames.GetAt(exames).Codigo
				        Set oExame.descExame     	= pRequest.DadosLIS.Exames.GetAt(exames).Descricao
				        Set oExame.mnemonico     	= ""
				        Set oExame.codigoBancada 	= pRequest.DadosLIS.Exames.GetAt(exames).SetorExame
				        Set oExame.descBancada   	= ""
				        
				        Set Status = oPedido.Exame.Insert(oExame)
			        }
			        Set oAtendimento.Pedido = oPedido
			        Set oAmostra.Atendimento = oAtendimento
			        
			       	Set Status = oMensagem.Amostra.Insert(oAmostra)
	        		If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
		        }
	        }
	        
        }
        Set pResponse.DadosStatusMV = oMensagem
        Set pResponse.DadosStatusLIS = pRequest.DadosLIS
    }    
    Catch objErro
    {
        Set Status = ##class(shift.utl.TrataExcecao).Excecao(objErro)
        Set msgErro = $System.Status.GetOneErrorText(Status)
        Set pResponse.Retorno = 0
        Set pResponse.DescricaoErro = msgErro
        $$$LOGWARNING(msgErro)
    }   
    Quit $System.Status.OK()
}

Method ConverteColeta(pRequest As shift.msg.shifthis.ConverteColetaRequest, Output pResponse As shift.msg.shifthis.ConverteColetaResponse) As %Status
{
	
	Try
    {
        Set Status = $$$OK
        Set cControleErro = 0
        Set msgErro = ""
        Set msgErroGeral = ""   
        Set pResponse = ##class(shift.msg.shifthis.ConverteColetaResponse).%New()
        
        Set objIntegracao = ##class(dado.shifthis.mv.TblIntegracao).IdxNomeOpen(pRequest.IdIntegracao)
        If '$ISOBJECT(objIntegracao)
        {
        	Set msgErro = "Integração "_pRequest.IdIntegracao_" não encontrada."
    		Set Status = $$$ERROR(5001,msgErro)
        	Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
        }
      	       
        Set sql = "SELECT ID FROM dado_shifthis_mv.TblControlePedido WHERE OrdemServicoApoio = ? AND Integracao = ? AND Tipo = ?"
        Set tStatement = ##class(%SQL.Statement).%New()
        Set Status = tStatement.%Prepare(sql)
        If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
        
        Set rset = tStatement.%Execute(pRequest.DadosOSLIS.CodigoOs, objIntegracao.%Id(),0)
        If rset.%Next()
        {
	        Set controlePedido = rset.ID
	        Set oControlePedido = ##class(dado.shifthis.mv.TblControlePedido).%OpenId(controlePedido,,.Status)
        	If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
	        
	        Set oMensagem = ##class(shift.xml.mv.cma.MensagemStatus).%New()
            Set oCabecalho = ##class(shift.xml.mv.cma.Cabecalho).%New()
            Set oCabecalho.mensagemID           		= oControlePedido.MensagemID
	        Set oCabecalho.versaoXML            		= $Case(oControlePedido.VersaoXML,"":1,:$ZStrip(oControlePedido.VersaoXML,"*C"))
	        Set oCabecalho.identificacaoCliente 		= oControlePedido.IdentificacaoCliente
	        Set oCabecalho.servico              		= "AMOSTRA_EXAME"
	        Set oCabecalho.dataHora             		= $ZDateTime($Horolog,3)
	        Set oCabecalho.empresaOrigem        		= objIntegracao.EmpresaOrigem        
	        Set oCabecalho.sistemaOrigem        		= objIntegracao.SistemaOrigem
	        Set oCabecalho.empresaDestino       		= objIntegracao.EmpresaDestino
	        Set oCabecalho.sistemaDestino       		= objIntegracao.SistemaDestino
	        Set oCabecalho.usuario              		= objIntegracao.UsuarioMV
	        Set oCabecalho.senha                		= objIntegracao.SenhaMV
	        Set oMensagem.Cabecalho             		= oCabecalho
	        
	        Set oAmostra = ##class(shift.xml.mv.cma.AmostraStatus).%New()	        
	        Set oAmostra.operacao        = "I"
			Set oAmostra.situacaoAmostra = "A"
			Set oAmostra.dataColeta      = pRequest.DadosOSLIS.Exames.GetAt(1).DataEvento_" "_pRequest.DadosOSLIS.Exames.GetAt(1).HoraEvento
			Set oAmostra.horaColeta      = pRequest.DadosOSLIS.Exames.GetAt(1).DataEvento_" "_pRequest.DadosOSLIS.Exames.GetAt(1).HoraEvento
			Set oAmostra.usuarioColeta   = pRequest.DadosOSLIS.Exames.GetAt(1).UsuarioEvento
			Set oAmostra.confirmada = "S"			

	        Set oAmostra.descricaoEtiqueta = ""	
	        
	        Set oAtendimento = ##class(shift.xml.mv.cma.atendimentoStatus).%New()
	        
	        Set sql1 = "SELECT Descricao FROM dado_shifthis_mv.TblDeParaConvenio WHERE ConvenioCliente = ? AND Integracao = ? AND Situacao = ?"
			Set tStatement1 = ##class(%SQL.Statement).%New()
			Set Status = tStatement1.%Prepare(sql1)
			If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
			
			Set rset1 = tStatement1.%Execute(oControlePedido.ConvenioCliente,pRequest.IdIntegracao,1)
			If rset1.%Next()
			{
    			Set oAtendimento.codigoConvenio    = oControlePedido.ConvenioCliente
	        	Set oAtendimento.descConvenio      = rset1.Descricao
			}
	        
	        Set oAtendimento.codigoAtendimento = $PIECE(pRequest.DadosOSLIS.PedidoCliente,"*",1)
	        Set oAtendimento.codigoPaciente    = oControlePedido.CodigoPacienteCliente
	        Set oAtendimento.nomePaciente      = oControlePedido.NomePaciente
	        Set oAtendimento.dataNascimento    = $ZDATE(oControlePedido.DataNascimentoPaciente,3)
	        Set oAtendimento.sexoPaciente      = ""
	        		        
	        Set oPedido = ##class(shift.xml.mv.cma.pedidoStatus).%New()
	        Set oPedido.codigoPedido = $PIECE(pRequest.DadosOSLIS.PedidoCliente,"*",2)
	        Set oPedido.codigoSetor  = pRequest.DadosOSLIS.Exames.GetAt(1).SetorExame
	        Set oPedido.dataPedido   = $ZDATE(oControlePedido.Data,3)
	        
	        Set qtdExame = pRequest.DadosOSLIS.Exames.Count()
        	For exame=1:1:qtdExame 
        	{
		        Set sqlExame = "SELECT CodigoItemPedido,DescExame,Material,DescricaoMaterial,Recipiente,DeParaExame->CodExameApoio, Amostra FROM dado_shifthis_mv.TblControleExame WHERE ControlePedido = ? AND CodExameCliente = ?"
		        Set tStatementExame = ##class(%SQL.Statement).%New()
		        Set Status = tStatementExame.%Prepare(sqlExame)
		        If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
		        Set rsetExame = tStatementExame.%Execute(controlePedido, pRequest.DadosOSLIS.Exames.GetAt(exame).Codigo)
		        If rsetExame.%Next()
		        {
			        If (rsetExame.Amostra '= "")
			        {
				        Set msgErro = "Amostra já enviada para a MV."
		    			Set Status = $$$ERROR(5001,msgErro)
		    			
		    			Set pResponse.Retorno = 0
		        		Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)			           
			        }
			        
			        Set oAmostra.codigoAmostra          = pRequest.DadosOSLIS.Exames.GetAt(1).Amostras.GetAt(1).Cbarra
		        	Set oAmostra.codigoAmostraDePara    = pRequest.DadosOSLIS.Exames.GetAt(1).Amostras.GetAt(1).Cbarra
			        Set oAmostra.codigoAmostraPAI       = ""
			        Set oAmostra.codigoAmostraPAIDepara = ""			        
					Set oAmostra.codigoMaterial         = rsetExame.Material
			        Set oAmostra.descMaterial           = ""
			        Set oAmostra.codigoTuboColeta       = $PIECE(rsetExame.Recipiente,"/",1)
			        Set oAmostra.descTuboColeta         = ""
			        
			        Set oExame = ##class(shift.xml.mv.cma.ExameStatus).%New()			       
				   	Set oExame.operacao      	= oAmostra.operacao
				   	Set oExame.codigoItemPedido = rsetExame.CodigoItemPedido
				    Set oExame.codigoExame   	= pRequest.DadosOSLIS.Exames.GetAt(exame).Codigo
			        Set oExame.descExame     	= pRequest.DadosOSLIS.Exames.GetAt(exame).Descricao
			        Set oExame.mnemonico     	= ""
			        Set oExame.codigoBancada 	= pRequest.DadosOSLIS.Exames.GetAt(exame).SetorExame
			        Set oExame.descBancada   	= ""
			        
			        Set Status = oPedido.Exame.Insert(oExame)
		        }
        	}
	        Set oAtendimento.Pedido = oPedido
	        Set oAmostra.Atendimento = oAtendimento
	        
	       	Set Status = oMensagem.Amostra.Insert(oAmostra)
    		If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
    		
    		Set pResponse.DadosStatusMV = oMensagem
        }
        Set pResponse.DadosOSLIS = pRequest.DadosOSLIS

	}
	Catch objErro
	{
	    Set Status = ##class(shift.utl.TrataExcecao).Excecao(objErro)
	    Set msgErro = $System.Status.GetOneErrorText(Status)
	    Set pResponse.Retorno = 0
	    Set pResponse.DescricaoErro = msgErro
	    $$$LOGWARNING(msgErro)
	}
	
	Quit $System.Status.OK()
}

Method ConverteRecoleta(pRequest As shift.msg.shifthis.ConverteRecoletaRequest, Output pResponse As shift.msg.shifthis.ConverteRecoletaResponse) As %Status
{
	
	Try
    {
        Set Status = $$$OK
        Set cControleErro = 0
        Set msgErro = ""
        Set msgErroGeral = ""
        Set oMensagem = ""
        
        Set pResponse = ##class(shift.msg.shifthis.ConverteRecoletaResponse).%New()
        
        Set objIntegracao = ##class(dado.shifthis.mv.TblIntegracao).IdxNomeOpen(pRequest.IdIntegracao)
        If '$ISOBJECT(objIntegracao)
        {
        	Set msgErro = "Integração "_pRequest.IdIntegracao_" não encontrada."
    		Set Status = $$$ERROR(5001,msgErro)
        	Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
        }
      	       
        Set sql = "SELECT ID FROM dado_shifthis_mv.TblControlePedido WHERE OrdemServicoApoio = ? AND Integracao = ? AND Tipo = ?"
        Set tStatement = ##class(%SQL.Statement).%New()
        Set Status = tStatement.%Prepare(sql)
        If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
        
        Set rset = tStatement.%Execute(pRequest.DadosOSLIS.CodigoOs, objIntegracao.%Id(),0)
        If rset.%Next()
        {
	        Set controlePedido = rset.ID
	        Set oControlePedido = ##class(dado.shifthis.mv.TblControlePedido).%OpenId(controlePedido,,.Status)
        	If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
	        
	        Set oMensagem = ##class(shift.xml.mv.cma.MensagemStatus).%New()
            Set oCabecalho = ##class(shift.xml.mv.cma.Cabecalho).%New()
            Set oCabecalho.mensagemID           		= oControlePedido.MensagemID
	        Set oCabecalho.versaoXML            		= $Case(oControlePedido.VersaoXML,"":1,:$ZStrip(oControlePedido.VersaoXML,"*C"))
	        Set oCabecalho.identificacaoCliente 		= oControlePedido.IdentificacaoCliente
	        Set oCabecalho.servico              		= "AMOSTRA_EXAME"
	        Set oCabecalho.dataHora             		= $ZDateTime($Horolog,3)
	        Set oCabecalho.empresaOrigem        		= objIntegracao.EmpresaOrigem        
	        Set oCabecalho.sistemaOrigem        		= objIntegracao.SistemaOrigem
	        Set oCabecalho.empresaDestino       		= objIntegracao.EmpresaDestino
	        Set oCabecalho.sistemaDestino       		= objIntegracao.SistemaDestino
	        Set oCabecalho.usuario              		= objIntegracao.UsuarioMV
	        Set oCabecalho.senha                		= objIntegracao.SenhaMV
	        Set oMensagem.Cabecalho             		= oCabecalho
	        
	        Set oAmostra = ##class(shift.xml.mv.cma.AmostraStatus).%New()
	        
	        If (pRequest.Log = "002" || pRequest.Log = "003") 
	        {
		        Set oAmostra.operacao = "E"
		        Set oAmostra.situacaoAmostra = "C"
		        Set oAmostra.confirmada = "N"
	        }
	        Else
	        {
		        Set oAmostra.operacao = "A"
		        If pRequest.Log = "007" 
		        {
			        Set oAmostra.situacaoAmostra = "R"
			        Set oAmostra.confirmada = "N"
		        }
		        Else
		        {
			        Set oAmostra.situacaoAmostra = "D"
			        Set oAmostra.confirmada = "S"
		        }
	        }
	        
	        
	        Set oAmostra.dataColeta      = pRequest.DadosOSLIS.Exames.GetAt(1).DataEvento_" "_pRequest.DadosOSLIS.Exames.GetAt(1).HoraEvento
			Set oAmostra.horaColeta      = pRequest.DadosOSLIS.Exames.GetAt(1).DataEvento_" "_pRequest.DadosOSLIS.Exames.GetAt(1).HoraEvento
			Set oAmostra.usuarioColeta   = pRequest.DadosOSLIS.Exames.GetAt(1).UsuarioEvento			
	        Set oAmostra.descricaoEtiqueta = ""	
	        
	        Set oAtendimento = ##class(shift.xml.mv.cma.atendimentoStatus).%New()
	        
	        Set sql1 = "SELECT Descricao FROM dado_shifthis_mv.TblDeParaConvenio WHERE ConvenioCliente = ? AND Integracao = ? AND Situacao = ?"
			Set tStatement1 = ##class(%SQL.Statement).%New()
			Set Status = tStatement1.%Prepare(sql1)
			If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
			
			Set rset1 = tStatement1.%Execute(oControlePedido.ConvenioCliente,pRequest.IdIntegracao,1)
			If rset1.%Next()
			{
    			Set oAtendimento.codigoConvenio    = oControlePedido.ConvenioCliente
	        	Set oAtendimento.descConvenio      = rset1.Descricao
			}
	        
	        Set oAtendimento.codigoAtendimento = $PIECE(pRequest.DadosOSLIS.PedidoCliente,"*",1)
	        Set oAtendimento.codigoPaciente    = oControlePedido.CodigoPacienteCliente
	        Set oAtendimento.nomePaciente      = oControlePedido.NomePaciente
	        Set oAtendimento.dataNascimento    = $ZDATE(oControlePedido.DataNascimentoPaciente,3)
	        Set oAtendimento.sexoPaciente      = ""
	        		        
	        Set oPedido = ##class(shift.xml.mv.cma.pedidoStatus).%New()
	        Set oPedido.codigoPedido = $PIECE(pRequest.DadosOSLIS.PedidoCliente,"*",2)
	        Set oPedido.codigoSetor  = pRequest.DadosOSLIS.Exames.GetAt(1).SetorExame
	        Set oPedido.dataPedido   = $ZDATE(oControlePedido.Data,3)
	        
	        Set qtdExame = pRequest.DadosOSLIS.Exames.Count()
        	For exame=1:1:qtdExame 
        	{
		        Set sqlExame = "SELECT CodigoItemPedido,DescExame,Material,DescricaoMaterial,Recipiente,DeParaExame->CodExameApoio, Amostra FROM dado_shifthis_mv.TblControleExame WHERE ControlePedido = ? AND CodExameCliente = ?"
		        Set tStatementExame = ##class(%SQL.Statement).%New()
		        Set Status = tStatementExame.%Prepare(sqlExame)
		        If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
		        
		        Set rsetExame = tStatementExame.%Execute(controlePedido, pRequest.DadosOSLIS.Exames.GetAt(exame).Codigo)
		        If rsetExame.%Next()
		        {
			        If (rsetExame.Amostra '= "")
			        {
				        If (pRequest.Log '= "002" && pRequest.Log '= "003") 
				        {
							Set oAmostra.codigoAmostra          = pRequest.DadosOSLIS.Exames.GetAt(1).Amostras.GetAt(1).Cbarra
							Set oAmostra.codigoAmostraDePara    = pRequest.DadosOSLIS.Exames.GetAt(1).Amostras.GetAt(1).Cbarra   
				        }
				        
				        Set oAmostra.codigoAmostraPAI       = $PIECE(rsetExame.Amostra,"/",1)
			        	Set oAmostra.codigoAmostraPAIDepara = $PIECE(rsetExame.Amostra,"/",1)
			        }
			        Else 
			        {
				        Set msgErro = "Amostra não encontrada para o Exame "_pRequest.DadosOSLIS.Exames.GetAt(exame).Codigo_"."
		    			Set Status = $$$ERROR(5001,msgErro)
		    			
		    			Set pResponse.Retorno = 0
		        		Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
			        }
			        
					Set oAmostra.codigoMaterial         = rsetExame.Material
			        Set oAmostra.descMaterial           = ""
			        Set oAmostra.codigoTuboColeta       = $PIECE(rsetExame.Recipiente,"/",1)
			        Set oAmostra.descTuboColeta         = ""
			        
			        Set oExame = ##class(shift.xml.mv.cma.ExameStatus).%New()			       
				   	Set oExame.operacao      	= oAmostra.operacao
				   	Set oExame.codigoItemPedido = rsetExame.CodigoItemPedido
				    Set oExame.codigoExame   	= pRequest.DadosOSLIS.Exames.GetAt(exame).Codigo
			        Set oExame.descExame     	= pRequest.DadosOSLIS.Exames.GetAt(exame).Descricao
			        Set oExame.mnemonico     	= ""
			        Set oExame.codigoBancada 	= pRequest.DadosOSLIS.Exames.GetAt(exame).SetorExame
			        Set oExame.descBancada   	= ""
			        
			        Set Status = oPedido.Exame.Insert(oExame)
		        }
        	}
	        Set oAtendimento.Pedido = oPedido
	        Set oAmostra.Atendimento = oAtendimento
	        
	       	Set Status = oMensagem.Amostra.Insert(oAmostra)
    		If $$$ISERR(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
    		
    		Set pResponse.DadosStatusMV = oMensagem
        }
        Set pResponse.DadosOSLIS = pRequest.DadosOSLIS
	}
	Catch objErro
	{
	    Set Status = ##class(shift.utl.TrataExcecao).Excecao(objErro)
	    Set msgErro = $System.Status.GetOneErrorText(Status)
	    Set pResponse.Retorno = 0
	    Set pResponse.DescricaoErro = msgErro
	    $$$LOGWARNING(msgErro)
	}
	Quit $System.Status.OK()
}

Method AgrupaAmostra(pRequest As shift.msg.shifthis.AgrupaAmostraRequest, Output pResponse As shift.msg.shifthis.AgrupaAmostraResponse) As %Status
{
	
	Try
    {	    
        Set Status = $$$OK
        Set cControleErro = 0
        Set msgErro = ""
        Set msgErroGeral = ""   
        Set listaAmostras = ""
        Set pResponse = ##class(shift.msg.shifthis.AgrupaAmostraResponse).%New()
        
        #DIM novoObjLIS As shift.xml.lis.customizacao.DadosRetornoStatus
      	#DIM objOs As shift.xml.lis.customizacao.OrdemServicoStatus
      	#DIM objExame As shift.xml.lis.customizacao.ExameStatus
        
        Set objIntegracao = ##class(dado.shifthis.mv.TblIntegracao).IdxNomeOpen(pRequest.IdIntegracao)
        If '$ISOBJECT(objIntegracao)
        {
        	Set msgErro = "Integração "_pRequest.IdIntegracao_" não encontrada."
    		Set Status = $$$ERROR(5001,msgErro)
        	Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
        }
      	
      	Set novoObjLIS = ##class(shift.xml.lis.customizacao.DadosRetornoStatus).%New()
      	Set objLIS = pRequest.DadosCustomizacaoLIS.%ConstructClone(1)
      	
      	Set qtdOS = objLIS.OrdemServico.Count()
      	For os=1:1:qtdOS
      	{
	      	
	      	Set objOs = objLIS.OrdemServico.GetAt(os)
	      	Set qtdExames = objOs.Exames.Count()
	      		      	
	      	For ex=1:1:qtdExames
	      	{		      	
		      	Set objExame = objOs.Exames.GetAt(ex)
		      	Set qtdAmostra = objExame.Amostras.Count()
		      	
		      	For amostra=1:1:qtdAmostra
		      	{			      	
			      	Set idAmostra = objExame.Amostras.GetAt(amostra).Cbarra
			      	
			      	If $LISTFIND(listaAmostras,idAmostra) = 0 
			      	{
			      		Set ordemServico = ##class(shift.xml.lis.customizacao.OrdemServicoStatus).%New()
			      		Set ordemServico.CodigoOs = objOs.CodigoOs
			      		Set ordemServico.PedidoCliente = objOs.PedidoCliente
			      		
			      		Set exame = ##class(shift.xml.lis.customizacao.ExameStatus).%New()
			      		Set exame.Codigo = objExame.Codigo
			      		Set exame.Mnemonico = objExame.Mnemonico
			      		Set exame.Descricao = objExame.Descricao
			      		Set exame.Status = objExame.Status
			      		Set exame.DataEvento = objExame.DataEvento
			      		Set exame.HoraEvento = objExame.HoraEvento
			      		Set exame.UsuarioEvento = objExame.UsuarioEvento
			      		Set exame.MotivoEvento = objExame.MotivoEvento
			      		Set exame.CdMotivoEvento = objExame.CdMotivoEvento
			      		Set exame.SetorExame = objExame.SetorExame	
			      		
			      		Set objAmostra = ##class(shift.xml.lis.customizacao.AmostraStatus).%New()
			      		Set objAmostra.Cbarra = idAmostra
			      		Set objAmostra.Tipo = objExame.Amostras.GetAt(amostra).Tipo
			      		Do exame.Amostras.Insert(objAmostra)
			      		
			      		Do ordemServico.Exames.Insert(exame)
			      		Do novoObjLIS.OrdemServico.Insert(ordemServico)
			      		Set $LIST(listaAmostras,*+1) = idAmostra
		      		}
		      		Else
		      		{
			      		Set posicaoOS = $LISTFIND(listaAmostras,idAmostra)
			      		Set ordemServico = novoObjLIS.OrdemServico.GetAt(posicaoOS)
			      		
			      		Set exame = ##class(shift.xml.lis.customizacao.ExameStatus).%New()
			      		Set exame.Codigo = objExame.Codigo
			      		Set exame.Mnemonico = objExame.Mnemonico
			      		Set exame.Descricao = objExame.Descricao
			      		Set exame.Status = objExame.Status
			      		Set exame.DataEvento = objExame.DataEvento
			      		Set exame.HoraEvento = objExame.HoraEvento
			      		Set exame.UsuarioEvento = objExame.UsuarioEvento
			      		Set exame.MotivoEvento = objExame.MotivoEvento
			      		Set exame.CdMotivoEvento = objExame.CdMotivoEvento
			      		Set exame.SetorExame = objExame.SetorExame
			      		
			      		Set objAmostra = ##class(shift.xml.lis.customizacao.AmostraStatus).%New()
			      		Set objAmostra.Cbarra = idAmostra
			      		Set objAmostra.Tipo = objExame.Amostras.GetAt(amostra).Tipo
			      		Do exame.Amostras.Insert(objAmostra)
			      		
			      		Do ordemServico.Exames.Insert(exame)
			      	}
		      	}		      	
	      	}
      	}
        
        Set pResponse.QtdOS = $LISTLENGTH(listaAmostras)
        Set pResponse.DadosLIS = objLIS
        Set pResponse.DadosLISAlterado = novoObjLIS

	}
	Catch objErro
	{
	    Set Status = ##class(shift.utl.TrataExcecao).Excecao(objErro)
	    Set msgErro = $System.Status.GetOneErrorText(Status)
	    Set pResponse.Retorno = 0
	    Set pResponse.DescricaoErro = msgErro
	    $$$LOGWARNING(msgErro)
	}
	
	Quit $System.Status.OK()
}

Method PreparaDadosOperadorCultura(pCodExameApoio As %String = "", pOrdemServicoApoio As %String = "", pParcial As %Boolean, pObjIntegracao As dado.shifthis.mv.TblIntegracao, pExame As shift.xml.lis.exp.resultado.Exame, ByRef pResultadoCultura As shift.xml.mv.cul.Resultado) As %Status
{
	Set Status = $$$OK
	If ((pParcial '= 1) && (pObjIntegracao.ExportaUsuariosDadosMV '= 1))
	{	
		If (pCodExameApoio = "") || (pOrdemServicoApoio = "")
		{
			Set Status = $$$ERROR(5001, "Os valores dos parâmetros devem ser informados.")
		    $$$ThrowStatus(Status)
		}
		
		Set oLogRequest = ##class(shift.msg.RecuperaInformacaoLogRequest).%New()
		Set oLogRequest.pExame = pCodExameApoio
		Set oLogRequest.pOs = pOrdemServicoApoio
		Set oLogRequest.Integracao = pObjIntegracao.Nome
		Set Status = ..SendRequestSync("Shift_Customizacao", oLogRequest,.oLogdResponse)
		If $System.Status.IsError(Status) Throw ##class(shift.utl.TrataExcecao).StatusExcecao(Status)
		
		If ($ISOBJECT(oLogdResponse.RecuperaInformacaoLogResult))
		{
			If (oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("230") '= "")
			{
				Set pResultadoCultura.operadorCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("230").Operador
				Set pResultadoCultura.dataHoraCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("230").DataHora
				If (pResultadoCultura.operadorCadastro = "USUARIOSISTEMA") 
				{
					If (oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("013") '= "") 
					{
						Set pResultadoCultura.operadorCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("013").Operador
						Set pResultadoCultura.dataHoraCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("013").DataHora
					}
					ElseIf (oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("051") '= "") 
					{
						Set pResultadoCultura.operadorCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("051").Operador
						Set pResultadoCultura.dataHoraCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("051").DataHora
					}
				}
			}
			ElseIf (oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("031") '= "")
			{
				Set pResultadoCultura.operadorCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("031").Operador
				Set pResultadoCultura.dataHoraCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("031").DataHora
			}
			ElseIf (oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("011") '= "")
			{
				Set pResultadoCultura.operadorCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("011").Operador
				Set pResultadoCultura.dataHoraCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("011").DataHora
			}
			ElseIf (oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("054") '= "")
			{
				Set pResultadoCultura.operadorCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("054").Operador			
				Set pResultadoCultura.dataHoraCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("054").DataHora
			}
			ElseIf (oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("319") '= "")
			{
				Set pResultadoCultura.operadorCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("319").Operador			
				Set pResultadoCultura.dataHoraCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("319").DataHora
			}
			ElseIf (oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("090") '= "")
			{
				Set pResultadoCultura.operadorCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("090").Operador			
				Set pResultadoCultura.dataHoraCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("090").DataHora
			}
			ElseIf (oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("089") '= "")
			{
				Set pResultadoCultura.operadorCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("089").Operador
				Set pResultadoCultura.dataHoraCadastro = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("089").DataHora
			}
						
			If (oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("048") '= "")
			{
				Set pResultadoCultura.operadorRevisao = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("048").Operador
				Set pResultadoCultura.dataHoraRevisao = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("048").DataHora
			}
			ElseIf (oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("013") '= "")
			{
		    	Set pResultadoCultura.operadorRevisao = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("013").Operador
		    	Set pResultadoCultura.dataHoraRevisao = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("013").DataHora
			}
			ElseIf (oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("051") '= "")
			{
		    	Set pResultadoCultura.operadorRevisao = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("051").Operador
		    	Set pResultadoCultura.dataHoraRevisao = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("051").DataHora
			}
			
			If (oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("013") '= "")
			{
				Set pResultadoCultura.operadorAssinatura = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("013").Operador
				Set pResultadoCultura.dataHoraAssinatura = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("013").DataHora
			}
			ElseIf (oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("051") '= "")
			{
				Set pResultadoCultura.operadorAssinatura = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("051").Operador
				Set pResultadoCultura.dataHoraAssinatura = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("051").DataHora
			}
			
			If (oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("025") '= "")
			{
				Set pResultadoCultura.operadorLiberacao = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("025").Operador
				Set pResultadoCultura.dataHoraLiberacao = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("025").DataHora
			} 
			ElseIf (oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("320") '= "")
			{
				Set pResultadoCultura.operadorLiberacao = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("320").Operador
				Set pResultadoCultura.dataHoraLiberacao = oLogdResponse.RecuperaInformacaoLogResult.LogInformation.GetAt("320").DataHora
			}
			
		}
				        
		Set pResultadoCultura.assinado = "S"
		Set pResultadoCultura.revisado = "S"
		Set pResultadoCultura.liberado = "S"			
	}
	Else
	{
		Set pResultadoCultura.operadorRevisao = pObjIntegracao.UsuarioRevisao
		Set pResultadoCultura.dataHoraRevisao = pExame.Liberacao.Data_" "_pExame.Liberacao.Hora

		Set pResultadoCultura.operadorAssinatura = pObjIntegracao.UsuarioAssinatura
		Set pResultadoCultura.dataHoraAssinatura = pExame.Liberacao.Data_" "_pExame.Liberacao.Hora

		Set pResultadoCultura.operadorLiberacao = pObjIntegracao.UsuarioLiberacao
		Set pResultadoCultura.dataHoraLiberacao = pExame.Liberacao.Data_" "_pExame.Liberacao.Hora

		Set pResultadoCultura.operadorCadastro = pObjIntegracao.UsuarioLiberacao
		Set pResultadoCultura.dataHoraCadastro = pExame.Liberacao.Data_" "_pExame.Liberacao.Hora

		Set pResultadoCultura.assinado = "N"
		Set pResultadoCultura.revisado = "N"
		Set pResultadoCultura.liberado = "N"
	}
	
	Quit Status
}

Method PreparaDadosOperadorMVNormal(pObjIntegracao As dado.shifthis.mv.TblIntegracao, pExame As shift.xml.lis.exp.resultado.Exame, ByRef pResultadoExame As shift.xml.mv.cma.Exame) As %Status
{
	Try 
	{
		Set Status = $$$OK
		
		Set pResultadoExame.operadorCadastro = pObjIntegracao.UsuarioCadastro
	    If (pObjIntegracao.UsuarioCadastro '= "")
	    { 
	    	Set pResultadoExame.dataHoraCadastro = pExame.Solicitacao.Data_" "_pExame.Solicitacao.Hora
	    }
	    
	    Set pResultadoExame.operadorRevisao = pObjIntegracao.UsuarioRevisao 
	    If (pObjIntegracao.UsuarioRevisao '= "") 
	    {
	    	Set pResultadoExame.dataHoraRevisao = pExame.Liberacao.Data_" "_pExame.Liberacao.Hora
	    }
	    
	    Set pResultadoExame.operadorAssinatura = pObjIntegracao.UsuarioAssinatura
	    If (pObjIntegracao.UsuarioAssinatura '= "") 
	    {
	    	Set pResultadoExame.dataHoraAssinatura = pExame.Liberacao.Data_" "_pExame.Liberacao.Hora
	    }
	    
	    Set pResultadoExame.operadorLiberacao = pObjIntegracao.UsuarioLiberacao 
	    If (pObjIntegracao.UsuarioLiberacao '= "") 
	    {
	    	Set pResultadoExame.dataHoraLiberacao = pExame.Liberacao.Data_" "_pExame.Liberacao.Hora
	    }
	}
	Catch
	{
		Set Status = ##class(shift.utl.TrataExcecao).Excecao(objErro)
        Set msgErro = $System.Status.GetOneErrorText(Status)
        Set pResponse.Retorno = 0
        Set pResponse.DescricaoErro = msgErro
        $$$LOGWARNING(msgErro)
	}
	
	Quit Status
}

Method PreparaDadosOperadorMVCultura(pObjIntegracao As dado.shifthis.mv.TblIntegracao, pExame As shift.xml.lis.exp.resultado.Exame, ByRef pResultadoCultura As shift.xml.mv.cul.Resultado) As %Status
{
	Try 
	{
		Set Status = $$$OK
		
		Set pResultadoCultura.revisado = "N"
		Set pResultadoCultura.assinado = "N"
		Set pResultadoCultura.liberado = "N"
		
		Set pResultadoCultura.operadorCadastro = pObjIntegracao.UsuarioCadastro
	    If (pObjIntegracao.UsuarioCadastro '= "")
	    { 
	    	Set pResultadoCultura.dataHoraCadastro = pExame.Solicitacao.Data_" "_pExame.Solicitacao.Hora
	    }
	    
	    Set pResultadoCultura.operadorRevisao = pObjIntegracao.UsuarioRevisao 
	    If (pObjIntegracao.UsuarioRevisao '= "") 
	    {
	    	Set pResultadoCultura.dataHoraRevisao = pExame.Liberacao.Data_" "_pExame.Liberacao.Hora
	    	Set pResultadoCultura.revisado = "S"
	    }
	    
	    Set pResultadoCultura.operadorAssinatura = pObjIntegracao.UsuarioAssinatura
	    If (pObjIntegracao.UsuarioAssinatura '= "") 
	    {
	    	Set pResultadoCultura.dataHoraAssinatura = pExame.Liberacao.Data_" "_pExame.Liberacao.Hora
	    	Set pResultadoCultura.assinado = "S"
	    }
	    
	    Set pResultadoCultura.operadorLiberacao = pObjIntegracao.UsuarioLiberacao 
	    If (pObjIntegracao.UsuarioLiberacao '= "") 
	    {
	    	Set pResultadoCultura.dataHoraLiberacao = pExame.Liberacao.Data_" "_pExame.Liberacao.Hora
	    	Set pResultadoCultura.liberado = "S"
	    }	
	}
	Catch
	{
		Set Status = ##class(shift.utl.TrataExcecao).Excecao(objErro)
        Set msgErro = $System.Status.GetOneErrorText(Status)
        Set pResponse.Retorno = 0
        Set pResponse.DescricaoErro = msgErro
        $$$LOGWARNING(msgErro)
	}
	
	Quit Status
}

XData MessageMap
{
<MapItems>
    <MapItem MessageType="shift.msg.ConverteObjShiftRequest"> 
        <Method>ConverteObjShift</Method>
    </MapItem>
    <MapItem MessageType="shift.msg.ConverteResNormalRequest"> 
        <Method>ConverteResultadoNormal</Method>
    </MapItem>
    <MapItem MessageType="shift.msg.ConverteResCulturaRequest"> 
        <Method>ConverteResultadoCultura</Method>
    </MapItem>
    <MapItem MessageType="shift.msg.ConverteObjCancelamentoRequest"> 
        <Method>ConverteObjCancelamento</Method>
    </MapItem>
    <MapItem MessageType="shift.msg.shifthis.ConverteStatusRequest"> 
        <Method>ConverteStatus</Method>
    </MapItem>
    <MapItem MessageType="shift.msg.shifthis.ConverteColetaRequest"> 
        <Method>ConverteColeta</Method>
    </MapItem>
    <MapItem MessageType="shift.msg.shifthis.ConverteRecoletaRequest"> 
        <Method>ConverteRecoleta</Method>
    </MapItem>
    <MapItem MessageType="shift.msg.shifthis.AgrupaAmostraRequest"> 
        <Method>AgrupaAmostra</Method>
    </MapItem>
</MapItems>
}

}
