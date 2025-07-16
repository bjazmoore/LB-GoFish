' ==============================
' Liberty BASIC Go Fish 
' ==============================

nomainwin

' --- Constants ---
global statePlayerTurn, statePlayerGoFish, stateShowingMessage
global stateAiTurn, stateAiGoFish, stateGameOver

statePlayerTurn = 1
statePlayerGoFish = 2
stateAiTurn = 3 
stateAiGoFish = 4 
stateGameOver = 5 
stateShowingMessage = 9

'---------------------------------------------------------
' I know - all these globals are messy.  I should have
' started out passing arguments, at some point it was no
' longer an option.
global cardWidth, cardHeight, windowWidth, windowHeight
global spacingW, spacingH, stackOffsetY
global thePlayer, theOpponent, deckTop, currentRankCount
global maxRanks, maxStack, buttonX, buttonY
global messageCount, xBtn, yBtn, windowOpen
global gameState, rank, lastFailedRank, action$
global lastFishedRank, rankRequested

cardWidth = 40
cardHeight = 100
spacingH = 250
spacingW = 10
stackOffsetY = 55
windowWidth = 720
windowHeight = 500
windowOpen = 0
currentRankCount = 0
lastFailedRank = 0
lastFishedRank = 0
rankRequested = 0

xBtn = windowWidth - 140
yBtn = windowHeight - 95

buttonX = windowWidth - 140
buttonY = 10

thePlayer = 1
theOpponent = 2
deckTop = 1
maxRanks = 13
maxStack = 4
gameState = 0

' --- Arrays ---
Dim deckCards(52)
Dim holdCards(2, 52)
Dim nCardsInHand(2)
Dim booksMade(2)
Dim memoryRanks(13)
Dim cardRect(13, 20)

Dim distinctRanks$(13)
Dim cardsPerRank(13)
Dim cardListPerRank$(13, 4)
Dim ranksReceivedThisTurn(13)
Dim ranksWithCount(13)
Dim eligibleRanks(13)
Dim rankCount(13)

Dim messageText$(5)
Dim buttonLabel$(5)
Dim buttonAction$(5)
messageCount = 0


' --- Start game ---
call startNewGame
wait

' ============================
' Subroutines & Logic
' ============================

Sub startNewGame
    call sortDeck
    call shuffleDeck
    deckTop = 1

    For j = 1 To 2
        For i = 1 To 9
            holdCards(j, i) = deckCards(deckTop)
            deckTop = deckTop + 1
        Next i
    Next j  

    nCardsInHand(1) = 9
    nCardsInHand(2) = 9
    booksMade(1) = 0
    booksMade(2) = 0

    books = checkBooks(thePlayer)
    books = checkBooks(theOpponent)

    firstTurn = int(rnd(1) * 2) + 1 
    if firstTurn = thePlayer then
        call queueMessage " You won the coin toss and go first.", "OK", "[playerTurn]"
        gameState = statePlayerTurn
    else
        call queueMessage " Computer won the coin toss and goes first.", "OK", "[aiTurn]"
        gameState = stateAiTurn
    end if

    call GameStep
End Sub

Sub GameStep
    
    if messageCount > 0 then
        gameState = stateShowingMessage
        call showHand
        exit sub
    end if
    
    select case gameState

        case statePlayerTurn
            'if the player has no cards - draw one.
            for i = 1 to 13
                ranksReceivedThisTurn(i) = 0
            next            
            if nCardsInHand(thePlayer) = 0 then
                cardsDrawn = 0
                while cardsDrawn < 5
                    newCard = drawFromDeck()
                    if newCard = 0 then exit while
                    cardsDrawn = cardsDrawn + 1
                    holdCards(thePlayer, cardsDrawn) = newCard
                wend
                nCardsInHand(thePlayer) = cardsDrawn
            
                if cardsDrawn > 0 then
                    call queueMessage "Your hand was empty. You drew " + str$(cardsDrawn) + " card(s).", "OK", "[aiTurn]"
                else
                    call queueMessage "Your hand was empty but the deck is empty.", "OK", "[aiTurn]"
                end if
            else
                ' Waits for player to click a card
                #g "color darkgreen"
                #g "backcolor darkgreen"
                #g "place "; xBtn; " "; yBtn
                #g "boxfilled "; xBtn + 80; " "; yBtn + 30
                #g "color white"
                #g "place 10 "; windowHeight - 90
                #g "\\ It is the player's turn - click a card to request that rank.                                                         "
            end if


        case statePlayerGoFish
        
            newCard = drawFromDeck()
            if newCard <> 0 then
                holdCards(thePlayer, nCardsInHand(thePlayer) + 1) = newCard
                nCardsInHand(thePlayer) = nCardsInHand(thePlayer) + 1
        
                drawnRank = value(newCard)
                cardName$ = pip$(drawnRank) + " of " + suit$(newCard)
        
                if drawnRank = rank then
                    ' The player drew the rank they asked for!
                    msg$ = "You drew the " + cardName$ + " which you asked for!"
                    
                    ' Check if this makes a book
                    bookMade = checkBooks(thePlayer)
                    if bookMade then
                        call queueMessage msg$ + " You completed a book go again!", "OK", "[playerTurn]"
                    else
                        call queueMessage msg$ + " You get another turn.", "OK", "[playerTurn]"
                    end if
        
                else
                    ' Different rank drawn
                    msg$ = "You drew the " + cardName$ + "."
        
                    ' Check if this different rank makes a book
                    bookMade = checkBooks(thePlayer)
                    if bookMade then
                        call queueMessage msg$ + " and completed a book, but your turn ends.", "OK", "[aiTurn]"
                    else
                        call queueMessage msg$ + " Your turn ends.", "OK", "[aiTurn]"
                    end if
                end if
            else
                call queueMessage "The deck is empty.", "OK", "[aiTurn]"
            end if



        case stateAiGoFish
        
            newCard = drawFromDeck()
            lastFishedRank = 0
            msg$ = "Computer "
        
            if newCard <> 0 then
        
                holdCards(theOpponent, nCardsInHand(theOpponent)+1) = newCard
                nCardsInHand(theOpponent) = nCardsInHand(theOpponent) + 1
        
                drawnRank = value(newCard)
                cardName$ = pip$(drawnRank) + " of " + suit$(newCard)
        
                if drawnRank = rank then
                    ' AI drew the rank it just asked for ? continues its turn
                    msg$ = msg$ + "drew the " + pip$(drawnRank) + " it asked for!  It"
                    ranksReceivedThisTurn(drawnRank) = 1
        
                    ' Check if it completes a book
                    bookMade = checkBooks(theOpponent)
                    if bookMade then
                        call queueMessage msg$ + " completed a book - turn continues.", "OK", "[aiTurn]"
                    else
                        call queueMessage msg$ + " will continue its turn.", "OK", "[aiTurn]"
                    end if
        
                else
                    ' Different rank drawn
                    msg$ = "Computer drew a card.  It"
        
                    bookMade = checkBooks(theOpponent)
                    if bookMade then
                        call queueMessage msg$ + " completed a different book - turn ends.", "OK", "[playerTurn]"
                    else
                        call queueMessage msg$ + "'s turn ends.", "OK", "[playerTurn]"
                    end if
                end if
        
                ' Save last fished rank for biasing future decisions
                lastFishedRank = drawnRank
        
            else
                call queueMessage "The deck is empty.", "OK", "[playerTurn]"
            end if



        case stateAiTurn
            'If AI has no cards then draw one.
            if nCardsInHand(theOpponent) = 0 then
                cardsDrawn = 0
                while cardsDrawn < 5
                    newCard = drawFromDeck()
                    if newCard = 0 then exit while
                    cardsDrawn = cardsDrawn + 1
                    holdCards(theOpponent, cardsDrawn) = newCard
                wend
                nCardsInHand(theOpponent) = cardsDrawn
            
                if cardsDrawn > 0 then
                    call queueMessage "Computer's hand was empty. Drew " + str$(cardsDrawn) + " card(s).", "OK", "[playerTurn]"
                else
                    call queueMessage "Computer's hand was empty but the deck is empty.", "OK", "[playerTurn]"
                end if
            else
                rank = chooseAIRank()
                
                if rank > 0 then
                    ' Check whether player has cards of that rank
                    playerHas = 0
                    For i = 1 to nCardsInHand(thePlayer)
                        if value(holdCards(thePlayer, i)) = rank then
                            playerHas = playerHas + 1
                        end if
                    Next i
                    
                    if playerHas > 0 then
                        call queueMessage "Computer asks for " + pip$(rank) + ". You have " + str$(playerHas) + ".", "OK", "[transferToAI_" + str$(rank) + "]"
                    else
                        call queueMessage "Computer asks for " + pip$(rank) + ". You have none.", "Go Fish", "[aiGoFish]"
                        lastFailedRank = rank
                    end if
                else
                    ' If no rank found, AI should draw instead
                    call queueMessage "Computer has no cards to ask for. Drawing from deck.", "OK", "[aiDraw]"
                end if
            end if


        case stateGameOver
            notice "The game is over.  Thank you for playing."
            close #g
            end

    end select
    
    if messageCount > 0 then
        call GameStep
    end if    

End Sub

Sub runAction action$

    select case action$

        case "[playerTurn]"
            gameState = statePlayerTurn

        case "[aiTurn]"
            gameState = stateAiTurn

        case "[playerGoFish]"
            gameState = statePlayerGoFish

        case "[aiGoFish]"
            gameState = stateAiGoFish

        case "[gameOver]"
            gameState = stateGameOver

        case else
            if left$(action$, 18) = "[transferToPlayer_" then
                rank = val(mid$(action$, 19))
                msg$ = transferCards$(theOpponent, thePlayer, rank)
                'check for a book being made
                bookMade = checkBooks(thePlayer)
                if bookMade then
                    call queueMessage "You made a book of ";pip$(bookMade);"!", "OK", "[playerTurn]"
                end if
                'if msg$ is not empty then cards were recieved.
                if len(msg$) > 0 then
                    call queueMessage "You received: " + msg$, "OK", "[playerTurn]"
                else
                    call queueMessage "No cards received.", "OK", "[playerTurn]"
                end if
            end if

            if left$(action$, 14) = "[transferToAI_" then
                rank = val(mid$(action$, 15))
                msg$ = transferCards$(thePlayer, theOpponent, rank)
                'check for a book being made
                bookMade = checkBooks(theOpponent)
                if bookMade then
                    call queueMessage "Computer made a book of ";pip$(bookMade);"!", "OK", "[aiTurn]"
                end if
                'if msg$ is not empty then cards were recieved.
                if len(msg$) > 0 then
                    call queueMessage "Computer received: " + msg$, "OK", "[aiTurn]"
                else
                    call queueMessage "Computer recieved NO cards.", "OK", "[aiTurn]"
                end if
            end if

    end select
    

    call GameStep

End Sub

[mouseClick]
    mx = MouseX
    my = MouseY
    
    ' Check for click on Help button
    if mx >= buttonX and mx <= buttonX + 80 and my >= buttonY and my <= buttonY + 30 then
        call showRulesNotice
        wait
    end if


    if gameState = stateShowingMessage then

        if mx >= xBtn and mx <= xBtn + 100 and my >= yBtn and my <= yBtn + 20 then
            action$ = buttonAction$(messageCount)
            messageCount = messageCount - 1
            call runAction action$
            wait
        end if
    else
        if gameState = statePlayerTurn then
            call detectCardClick mx, my
            wait
        end if
    end if

    wait


Sub detectCardClick mx, my

    foundCard = 0
    For i = 1 To currentRankCount
        numCards = cardsPerRank(i)
        For k = numCards To 1 Step -1
            xLeft = cardRect(i, k + (1 - 1) * 4)
            yTop = cardRect(i, k + (2 - 1) * 4)
            xRight = cardRect(i, k + (3 - 1) * 4)
            yBottom = cardRect(i, k + (4 - 1) * 4)
            if mx >= xLeft and mx <= xRight and my >= yTop and my <= yBottom then
                foundCard = cardRect(i, k + (5 - 1) * 4)
                exit for
            end if
        Next k
    Next i

    if foundCard > 0 then
        rank = value(foundCard)
        call handlePlayerAsk rank
    end if
End Sub

Sub handlePlayerAsk rank
    count = 0
    For i = 1 To nCardsInHand(theOpponent)
        if value(holdCards(theOpponent, i)) = rank then count = count + 1
    Next i

    if count > 0 then
        call queueMessage "Computer has " + str$(count) + " cards of " + pip$(rank) + ".", "OK", "[transferToPlayer_" + str$(rank) + "]"
    else
        call queueMessage "Computer has no ";pip$(rank);". Go Fish!", "Go Fish", "[playerGoFish]"
    end if
    
    'show the board again
    call GameStep
End Sub

'-------------------------------------
' Choose a rank for the AI to request

Function chooseAIRank()

    result = 0
    For i = 1 To 13
        ranksWithCount(i) = 0
        eligibleRanks(i) = 0
    Next i

    
    ' If AI has no cards, no rank to choose
    If nCardsInHand(theOpponent) = 0 Then
        chooseAIRank = 0
        Exit Function
    End If

    ' Step 1 - Build array of how many cards AI has of each rank
    For i = 1 To nCardsInHand(theOpponent)
        r = value(holdCards(theOpponent, i))
        ranksWithCount(r) = ranksWithCount(r) + 1
    Next i

    ' Step 2 - Priority #1: check memoryRanks (what player previously asked for)
    For i = 1 To 13
        If memoryRanks(i) > 0 And ranksWithCount(i) > 0 Then
            result = i
            Exit for
        End If
    Next i

    ' Step 3 - Priority #2: prefer ranks held in multiples (>1) about 33% of time    
    eligibleCount = 0
    if result = 0 then
        For i = 1 To 13
            If ranksWithCount(i) > 1 And ranksReceivedThisTurn(i) = 0 Then
                eligibleCount = eligibleCount + 1
                eligibleRanks(eligibleCount) = i
            End If
        Next i
    
        If eligibleCount > 0 Then
            toss = Int(Rnd(1) * 2) + 3    ' 1 to 3
            If toss = 1 Then
                which = Int(Rnd(1) * eligibleCount) + 1
                result = eligibleRanks(which)
            End If
        End If
    end if
    
    ' Step 3.5 - Bias toward last fished card
    if result = 0 and lastFishedRank > 0 then
        if ranksWithCount(lastFishedRank) > 0 and ranksReceivedThisTurn(lastFishedRank) = 0 then
            toss = Int(Rnd(1) * 4) + 1   ' values 1..4
            if toss <= 3 then
                result = lastFishedRank
            end if
        end if
    end if

    
    'if we got this far with a result then we can return that result
    if result > 0 then
        chooseAIRank = result
        exit function
    end if    

    ' Step 4 - Remove ranks AI received this turn from consideration
    eligibleCount = 0
    For i = 1 To 13
        If ranksWithCount(i) > 0 Then
            If ranksReceivedThisTurn(i) = 0 Then
                eligibleCount = eligibleCount + 1
                eligibleRanks(eligibleCount) = i
            End If
        End If
    Next i
    
    If eligibleCount > 0 Then
        which = Int(Rnd(1) * eligibleCount) + 1
        candidateRank = eligibleRanks(which)
    Else
        ' Only ranks left are ones just received
        eligibleCount = 0
        For i = 1 To 13
            If ranksWithCount(i) > 0 And ranksReceivedThisTurn(i) = 1 Then
                eligibleCount = eligibleCount + 1
                eligibleRanks(eligibleCount) = i
            End If
        Next i
        
        If eligibleCount > 0 Then
            which = Int(Rnd(1) * eligibleCount) + 1
            candidateRank = eligibleRanks(which)
        Else
            candidateRank = 0
        End If
    End If
    
    ' Step 5 - Avoid repeating last failed request if possible
    If candidateRank = lastFailedRank And nCardsInHand(theOpponent) > 1 Then
        skip = Int(Rnd(1) * 2) + 1
        If skip = 1 Then
            eligibleCount = 0
            For i = 1 To 13
                If ranksWithCount(i) > 0 And i <> lastFailedRank Then
                    eligibleCount = eligibleCount + 1
                    eligibleRanks(eligibleCount) = i
                End If
            Next i
    
            If eligibleCount > 0 Then
                which = Int(Rnd(1) * eligibleCount) + 1
                candidateRank = eligibleRanks(which)
            End If
        End If
    End If

    
    ' Validate that the chosen rank is actually in hand
    If candidateRank > 0 And ranksWithCount(candidateRank) > 0 Then
        chooseAIRank = candidateRank
    Else
        print "ERROR - we should not ever get here!"
        eligibleCount = 0
        For i = 1 To 13
            If ranksWithCount(i) > 0 Then
                eligibleCount = eligibleCount + 1
                eligibleRanks(eligibleCount) = i
            End If
        Next i
        
        If eligibleCount > 0 Then
            which = Int(Rnd(1) * eligibleCount) + 1
            candidateRank = eligibleRanks(which)
            chooseAIRank = candidateRank
        Else
            chooseAIRank = 0
        End If
    End If
    
End Function



Function transferCards$(fromPlayer, toPlayer, rank)
    msg$ = ""
    For i = nCardsInHand(fromPlayer) To 1 Step -1
        if value(holdCards(fromPlayer, i)) = rank then
            c = holdCards(fromPlayer, i)
            pip$ = pip$(value(c))
            suit$ = suit$(c)
            msg$ = msg$ + pip$ + " " + suit$(c) + "  "
            holdCards(toPlayer, nCardsInHand(toPlayer)+1) = c
            nCardsInHand(toPlayer) = nCardsInHand(toPlayer)+1
            call removeCardFromHand fromPlayer, i
        end if
    Next i
    
    if toPlayer = theOpponent then
        ranksReceivedThisTurn(rank) = 1
    end if

    transferCards$ = msg$
End Function


Sub removeCardFromHand player, index
    For i = index To nCardsInHand(player) - 1
        holdCards(player, i) = holdCards(player, i + 1)
    Next i
    nCardsInHand(player) = nCardsInHand(player) - 1
End Sub

Function checkBooks(player)

    bookMade = 0
    for x = 1 to 13
        rankCount(x) = 0
    next    
    
    For i = 1 To nCardsInHand(player)
        rankCount(value(holdCards(player, i))) = rankCount(value(holdCards(player, i))) + 1
    Next i

    For i = 1 To 13
        if rankCount(i) = 4 then
            call removeRankFromHand player, i
            booksMade(player) = booksMade(player) + 1
            call checkForGameOver
            bookMade = i
            exit for
        end if
    Next i

    checkBooks = bookMade
End Function


Sub removeRankFromHand player, rank
    For i = nCardsInHand(player) To 1 Step -1
        if value(holdCards(player, i)) = rank then
            call removeCardFromHand player, i
        end if
    Next i
End Sub


Sub checkForGameOver
    if booksMade(1) >= 7 or booksMade(2) >= 7 then
        if booksMade(1) > booksMade(2) then
            call queueMessage "Game over! You win.", "OK", "[gameOver]"
        else
            call queueMessage "Game over! Computer wins.", "OK", "[gameOver]"
        end if
    end if
End Sub


Sub showHand
    call sortHand thePlayer
    currentRankCount = 0

    For i = 1 To nCardsInHand(thePlayer)
        card = holdCards(thePlayer, i)
        rankNum = value(card)
        pip$ = pip$(rankNum)
        rankLetter$ = rankLetter$(pip$)
        if rankNum > 1 and rankNum < 11 then
            rankLetter$ = str$(rankNum)
        end if

        found = 0
        For j = 1 To currentRankCount
            if distinctRanks$(j) = rankLetter$ then
                found = j
                exit for
            end if
        Next j

        if found = 0 then
            currentRankCount = currentRankCount + 1
            distinctRanks$(currentRankCount) = rankLetter$
            cardsPerRank(currentRankCount) = 1
            cardListPerRank$(currentRankCount, 1) = str$(card)
        else
            cardsPerRank(found) = cardsPerRank(found) + 1
            cardListPerRank$(found, cardsPerRank(found)) = str$(card)
        end if
    Next i

    call drawBoard currentRankCount
End Sub

'----------------------------------------------
' Draw the playing board

Sub drawBoard currentRankCount
    if windowOpen = 0 then
        WindowWidth = windowWidth
        WindowHeight = windowHeight
        UpperLeftX = (DisplayWidth - windowWidth) / 2
        UpperLeftY = (DisplayHeight - windowHeight) / 2
        open "Go Fish" for graphics as #g
        #g "trapclose [quit]"
        #g "when leftButtonDown [mouseClick]"
        
        'if running this in Just BASIC remove the next two lines.
        h1 = hwnd(#g)
        call ShowScrollBar h1, 3, 0
        
        windowOpen = 1
    end if

    #g "down"
    #g "fill darkgreen"
    #g "flush"
    
    ' Draw Help Button (upper right corner)
    
    #g "color black"
    #g "backcolor white"
    #g "place "; buttonX; " "; buttonY
    #g "boxfilled "; buttonX + 80; " "; buttonY + 30
    
    #g "color darkgreen"
    #g "place "; buttonX + 26; " "; buttonY + 5
    #g "\\"; "Help"


    #g "color white"
    #g "backcolor darkgreen"
    #g "place 20 30"
    #g "\"; "Computer cards: " + str$(nCardsInHand(theOpponent))
    #g "place 20 50"
    #g "\"; "Computer books: " + str$(booksMade(theOpponent))
    #g "place 20 70"
    #g "\"; "Player books: " + str$(booksMade(thePlayer))
    #g "place 20 90"
    #g "\"; "Deck cards left: " + str$(52 - deckTop + 1)

    startX = spacingW
    baseY = windowHeight - cardHeight - spacingH

    For i = 1 To currentRankCount
        rankLetter$ = distinctRanks$(i)
        numCards = cardsPerRank(i)

        For k = 1 To numCards
            card = val(cardListPerRank$(i, k))
            pip$ = pip$(value(card))
            suitName$ = suit$(card)
            suitLetter$ = suitLetter$(suitName$)

            x = startX + (i - 1) * (cardWidth + spacingW)
            y = baseY + (k - 1) * stackOffsetY

            cardRect(i, k + (1 - 1) * 4) = x
            cardRect(i, k + (2 - 1) * 4) = y
            cardRect(i, k + (3 - 1) * 4) = x + cardWidth
            cardRect(i, k + (4 - 1) * 4) = y + cardHeight
            cardRect(i, k + (5 - 1) * 4) = card

            #g "color black"
            #g "backcolor white"
            #g "place "; x; " "; y
            #g "boxfilled "; x + cardWidth; " "; y + cardHeight

            #g "color black"
            if len(rankLetter$) = 2 then
                textX = x + 11
            else
                textX = x + 15
            end if
            textY = y + 12
            #g "place "; textX; " "; textY
            #g "\\"; rankLetter$

            if suitLetter$ = "H" or suitLetter$ = "D" then
                #g "color red"
            else
                #g "color black"
            end if
            textX = x + 14
            textY = y + 28
            #g "place "; textX; " "; textY
            #g "\\"; suitLetter$
        Next k
    Next i

    call drawMessageBox
End Sub

Sub ShowScrollBar hW, lFlag, bShow
    'hW=handle of graphicbox
    'flags=_SB_BOTH,_SB_HORZ,_SB_VERT
    'bShow, 1=show, 0=hide
    CallDLL #user32, "ShowScrollBar",hW as uLong,lFlag As Long,bShow As Boolean,re As Boolean
End Sub

Sub drawMessageBox
    if messageCount = 0 then exit sub

    msg$ = messageText$(messageCount)
    label$ = buttonLabel$(messageCount)
    lblAdjust = 0
    if len(label$) <= 2 then lblAdjust = 15

    #g "color white"
    #g "backcolor darkgreen"
    #g "place 10 "; windowHeight - 90
    #g "\\"; msg$

    #g "color black"
    #g "backcolor white"
    #g "place "; xBtn; " "; yBtn
    #g "boxfilled "; xBtn + 80; " "; yBtn + 30
    #g "color darkgreen"
    #g "place "; xBtn + 13 + lblAdjust; " "; yBtn + 4
    #g "\\"; label$
End Sub

Sub queueMessage msg$, label$, action$
    messageCount = messageCount + 1
    messageText$(messageCount) = msg$
    buttonLabel$(messageCount) = label$
    buttonAction$(messageCount) = action$
End Sub


Function drawFromDeck()
    if deckTop > 52 then
        drawFromDeck = 0
    else
        drawFromDeck = deckCards(deckTop)
        deckTop = deckTop + 1
    end if
End Function

Sub sortHand player
    Dim sortKeys(52)
    Dim tempCards(52)
    For i = 1 To nCardsInHand(player)
        c = holdCards(player, i)
        sortKeys(i) = value(c) * 10 + suitOrder(suit$(c))
        tempCards(i) = c
    Next i

    For i = 1 To nCardsInHand(player) - 1
        For j = i + 1 To nCardsInHand(player)
            if sortKeys(j) < sortKeys(i) then
                t = sortKeys(i)
                sortKeys(i) = sortKeys(j)
                sortKeys(j) = t
                t = tempCards(i)
                tempCards(i) = tempCards(j)
                tempCards(j) = t
            end if
        Next j
    Next i

    For i = 1 To nCardsInHand(player)
        holdCards(player, i) = tempCards(i)
    Next i
End Sub

[quit]
    close #g
    end
    
Sub showRulesNotice
    rules$ = "Go Fish Rules (Short Version):" + chr$(13) + chr$(13) _
        + "- Ask a player for a rank you have." + chr$(13) _
        + "- If they have it, you get the cards and go again." + chr$(13) _
        + "- If not, go fish: draw from deck." + chr$(13) _
        + "- If your draw matches your ask, you keep going." + chr$(13) _
        + "- Collect 4 cards of same rank to make a book." + chr$(13) _
        + "- First to 7 books wins (our house rule!)."

    Notice rules$
End Sub

    
'--------------------------------------
' Deck Management

Sub sortDeck
    For i = 1 To 52
        deckCards(i) = i
    Next i
End Sub

Sub shuffleDeck
    For i = 52 To 1 Step -1
        x = int(rnd(1) * i) + 1
        temp = deckCards(x)
        deckCards(x) = deckCards(i)
        deckCards(i) = temp
    Next i
End Sub

Function suit$(deckValue)
    cardSuit$ = "Spades Hearts Clubs Diamonds"
    suit = int(deckValue / 13)
    if deckValue mod 13 = 0 then suit = suit - 1
    suit$ = word$(cardSuit$, suit + 1)
End Function

Function value(deckValue)
    value = deckValue mod 13
    if value = 0 then value = 13
End Function

Function pip$(faceValue)
    pipLabel$ = "Ace Deuce Three Four Five Six Seven Eight Nine Ten Jack Queen King"
    pip$ = word$(pipLabel$, faceValue)
End Function

Function suitLetter$(suitName$)
    select case suitName$
        case "Spades": suitLetter$ = "S"
        case "Hearts": suitLetter$ = "H"
        case "Clubs": suitLetter$ = "C"
        case "Diamonds": suitLetter$ = "D"
    end select
End Function

Function rankLetter$(pip$)
    select case pip$
        case "Ace": rankLetter$ = "A"
        case "Jack": rankLetter$ = "J"
        case "Queen": rankLetter$ = "Q"
        case "King": rankLetter$ = "K"
        case else
            rankLetter$ = left$(pip$, 1)
    end select
End Function

Function suitOrder(suitName$)
    select case suitName$
        case "Spades": suitOrder = 1
        case "Hearts": suitOrder = 2
        case "Diamonds": suitOrder = 3
        case "Clubs": suitOrder = 4
    end select
End Function                     
